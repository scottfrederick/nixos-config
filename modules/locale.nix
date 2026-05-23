{ ... }:
{
  # ============================================================
  # Locale & time. Source: en_US.UTF-8; timezone was unrecorded
  # in inventory — REVIEW: set yours.
  # ============================================================
  time.timeZone = "America/Denver";   # TODO: confirm timezone for the new machine

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      # REVIEW: source had Ubuntu language-pack-{ar,de,en,es,fr,it,ja,pt,ru,zh-hans,zh-hant}
      # installed but inventory could not determine which were actually used.
      # Uncomment any locales you want available system-wide:
      # "de_DE.UTF-8/UTF-8"
      # "es_ES.UTF-8/UTF-8"
      # "fr_FR.UTF-8/UTF-8"
      # "it_IT.UTF-8/UTF-8"
      # "ja_JP.UTF-8/UTF-8"
      # "pt_BR.UTF-8/UTF-8"
      # "ru_RU.UTF-8/UTF-8"
      # "zh_CN.UTF-8/UTF-8"
      # "zh_TW.UTF-8/UTF-8"
      # "ar_SA.UTF-8/UTF-8"
    ];
  };
}
