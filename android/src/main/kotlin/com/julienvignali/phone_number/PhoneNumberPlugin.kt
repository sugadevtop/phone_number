package com.julienvignali.phone_number

import androidx.annotation.NonNull
import com.google.i18n.phonenumbers.PhoneNumberUtil
import com.google.i18n.phonenumbers.Phonenumber.PhoneNumber
import com.google.i18n.phonenumbers.PhoneNumberUtil.PhoneNumberType
import com.google.i18n.phonenumbers.PhoneNumberUtil.PhoneNumberFormat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.lang.Exception

const val CHANNEL_NAME: String = "com.julienvignali/phone_number"

class PhoneNumberPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel

  private val util: PhoneNumberUtil = PhoneNumberUtil.getInstance()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
    channel.setMethodCallHandler(this)
  }

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
      channel.setMethodCallHandler(PhoneNumberPlugin())
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "parse" -> parse(call, result)
      "format" -> format(call, result)
      "getRegions" -> {
        val map = mutableMapOf<String, Int>()
        util.supportedRegions.forEach { r -> map[r] = util.getCountryCodeForRegion(r) }
        result.success(map)
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun parse(@NonNull call: MethodCall, @NonNull result: Result) {
    val string = call.argument<String>("string")
    val region = call.argument<String>("region")
    val ignoreType = call.argument<Boolean>("ignoreType") ?: false

    if (string.isNullOrEmpty()) {
      result.error("InvalidArgument", "Number string can't be null", null)
      return
    }

    val phoneNumber = parsePhoneNumber(string, region)

    if (phoneNumber != null) {
      val isValid = if (region.isNullOrBlank()) {
        util.isValidNumber(phoneNumber)
      } else {
        util.isValidNumberForRegion(phoneNumber, region)
      }

      if (isValid) {
        val type = if (ignoreType) {
          PhoneNumberType.UNKNOWN
        } else {
          util.getNumberType(phoneNumber)
        }
        val map = mapOf<String, Any>(
                "type" to type.normalized(),
                "e164" to util.format(phoneNumber, PhoneNumberFormat.E164),
                "international" to util.format(phoneNumber, PhoneNumberFormat.INTERNATIONAL),
                "national" to util.format(phoneNumber, PhoneNumberFormat.NATIONAL),
                "country_code" to phoneNumber.countryCode,
                "number_string" to phoneNumber.rawInput
        )
        result.success(map)
      } else {
        result.error("InvalidNumber", "Number $string is invalid", null)
      }
    } else {
      result.error("InvalidNumber", "Number $string is invalid", null)
    }
  }

  private fun format(@NonNull call: MethodCall, @NonNull result: Result) {
    val string = call.argument<String>("string")
    val region = call.argument<String>("region")

    if (string == null || region == null) {
      result.error("InvalidArgument", "Number string and region can't be null", null)
      return
    }

    var formatted = ""
    val formatter = util.getAsYouTypeFormatter(region)
    string.forEach { char -> formatted = formatter.inputDigit(char) }

    result.success(formatted)
  }

  private fun parsePhoneNumber(@NonNull string: String, region: String?): PhoneNumber? {
    return try {
      util.parse(string, region)
    } catch (e: Exception) {
      null
    }
  }
}

fun PhoneNumberType.normalized(): String {
  return when (this) {
    PhoneNumberType.MOBILE -> "mobile"
    PhoneNumberType.FIXED_LINE_OR_MOBILE -> "fixedOrMobile"
    PhoneNumberType.FIXED_LINE -> "fixedLine"
    PhoneNumberType.TOLL_FREE -> "tollFree"
    PhoneNumberType.PREMIUM_RATE -> "premiumRate"
    PhoneNumberType.SHARED_COST -> "sharedCost"
    PhoneNumberType.VOIP -> "voip"
    PhoneNumberType.PERSONAL_NUMBER -> "personalNumber"
    PhoneNumberType.PAGER -> "pager"
    PhoneNumberType.UAN -> "uan"
    PhoneNumberType.VOICEMAIL -> "voicemail"
    PhoneNumberType.UNKNOWN -> "unknown"
    else -> "notParsed"
  }
}