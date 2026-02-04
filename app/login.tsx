import { router } from "expo-router";
import { useState } from "react";
import { View, Text, TextInput, Pressable } from "react-native";
import { upsertUserByPhone } from "../src/userRepo";

export default function Login() {
  const [phone, setPhone] = useState("");

  async function onContinue() {
    const p = phone.trim();
    if (!p) return;
    // DEMO LOGIN: tạo user theo SĐT để chạy ngay.
    // Bước tiếp theo mình sẽ nâng lên OTP thật giống WhatsApp.
    await upsertUserByPhone(p);
    router.replace("/home");
  }

  return (
    <View style={{ flex: 1, padding: 24, gap: 12 }}>
      <Text style={{ fontSize: 18, fontWeight: "800" }}>Nhập số điện thoại</Text>
      <TextInput
        value={phone}
        onChangeText={setPhone}
        placeholder="VD: +84901234567"
        style={{ borderWidth: 1, borderRadius: 12, padding: 12 }}
        autoCapitalize="none"
      />
      <Pressable onPress={onContinue} style={{ padding: 14, borderRadius: 12, backgroundColor: "#111" }}>
        <Text style={{ color: "#fff", textAlign: "center", fontWeight: "700" }}>
          Tiếp tục
        </Text>
      </Pressable>
      <Text style={{ opacity: 0.65 }}>
        (Demo để chạy ngay) Bước sau sẽ đổi sang OTP số điện thoại.
      </Text>
    </View>
  );
}
