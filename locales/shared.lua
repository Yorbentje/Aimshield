local L0_1, L1_1
L0_1 = Locales
if not L0_1 then
  L0_1 = {}
end
Locales = L0_1
function L0_1(A0_2, ...)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  if not A0_2 then
    L1_2 = print
    L2_2 = "[^1ERROR^7] Resource ^5%s^7: Geen parameter voor Translate!"
    L3_2 = L2_2
    L2_2 = L2_2.format
    L4_2 = GetInvokingResource
    L4_2 = L4_2()
    if not L4_2 then
      L4_2 = GetCurrentResourceName
      L4_2 = L4_2()
    end
    L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2, L4_2)
    L1_2(L2_2, L3_2, L4_2, L5_2)
    L1_2 = "Translate parameter is nil!"
    return L1_2
  end
  L1_2 = Locales
  L2_2 = Config
  L2_2 = L2_2.Locale
  L1_2 = L1_2[L2_2]
  if L1_2 then
    L1_2 = Locales
    L2_2 = Config
    L2_2 = L2_2.Locale
    L1_2 = L1_2[L2_2]
    L1_2 = L1_2[A0_2]
    if L1_2 then
      L1_2 = string
      L1_2 = L1_2.format
      L2_2 = Locales
      L3_2 = Config
      L3_2 = L3_2.Locale
      L2_2 = L2_2[L3_2]
      L2_2 = L2_2[A0_2]
      L3_2, L4_2, L5_2 = ...
      return L1_2(L2_2, L3_2, L4_2, L5_2)
  end
  else
    L1_2 = Config
    L1_2 = L1_2.Locale
    if "en" ~= L1_2 then
      L1_2 = Locales
      L1_2 = L1_2.en
      if L1_2 then
        L1_2 = Locales
        L1_2 = L1_2.en
        L1_2 = L1_2[A0_2]
        if L1_2 then
          L1_2 = string
          L1_2 = L1_2.format
          L2_2 = Locales
          L2_2 = L2_2.en
          L2_2 = L2_2[A0_2]
          L3_2, L4_2, L5_2 = ...
          return L1_2(L2_2, L3_2, L4_2, L5_2)
      end
    end
    else
      L1_2 = "Translation ["
      L2_2 = Config
      L2_2 = L2_2.Locale
      L3_2 = "]["
      L4_2 = A0_2
      L5_2 = "] does not exist"
      L1_2 = L1_2 .. L2_2 .. L3_2 .. L4_2 .. L5_2
      return L1_2
    end
  end
end
Translate = L0_1
function L0_1(A0_2, ...)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Translate
  L2_2 = A0_2
  L3_2, L4_2, L5_2 = ...
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L3_2 = L1_2
  L2_2 = L1_2.gsub
  L4_2 = "^%l"
  L5_2 = string
  L5_2 = L5_2.upper
  return L2_2(L3_2, L4_2, L5_2)
end
TranslateCap = L0_1
L0_1 = Translate
_ = L0_1
L0_1 = TranslateCap
_U = L0_1
