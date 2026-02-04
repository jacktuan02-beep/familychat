import React, { useState } from "react";
import { View, Text, TextInput, Pressable, Alert } from "react-native";
import { FirebaseRecaptchaVerifierModal } from "expo-firebase-recaptcha";
import { PhoneAuthProvider, signInWithCredential, signInWithPhoneNumber } from "firebase/auth";
import { auth } from "../../src/lib/firebase";
import { router } from "expo-router";
import { upsertProfile } from "../../src/features/friends/api";
import { t } from "../../src/i18n/t";

export default function Login() {
  const recaptchaRef = React.useRef<FirebaseRecaptchaVerifierModal>(null);
  const [phone, setPhone] = useState("");
  const [verificationId, setVerificationId] = useState<string | null>(null);
  const [code, setCode] = useState("");

  async function send() {
    try {
      const full = phone.startsWith("+") ? phone : `+84${phone.replace(/^0/, "")}`;
      const confirmation = await signInWithPhoneNumber(auth, full, recaptchaRef.current as any);
      setVerificationId(confirmation.verificationId);
      Alert.alert("OK", "Đã gửi OTP");
    } catch (e: any) {
      Alert.alert("Lỗi", e?.message ?? String(e));
    }
  }

  async function verify() {
    try {
      if (!verificationId) return;
      const credential = PhoneAuthProvider.credential(verificationId, code);
      const res = await signInWithCredential(auth, credential);
      const p = phone.startsWith("+") ? phone : `+84${phone.replace(/^0/, "")}`;
      await upsertProfile(res.user.uid, p);
      router.replace("/(tabs)");
    } catch (e: any) {
      Alert.alert("Lỗi", e?.message ?? String(e));
    }
  }

  return (
    <View style={{ flex: 1, padding: 20, justifyContent: "center", gap: 12 }}>
      <FirebaseRecaptchaVerifierModal
        ref={recaptchaRef}
        firebaseConfig={{
          apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY!,
          authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN!,
          projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID!,
          storageBucket: process.env.EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET!,
          messagingSenderId: process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID!,
          appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID!,
        }}
        attemptInvisibleVerification
      />

      <Text style={{ fontSize: 22, fontWeight: "700" }}>{t("loginTitle")}</Text>

      <TextInput
        placeholder={t("phone")}
        value={phone}
        onChangeText={setPhone}
        keyboardType="phone-pad"
        style={{ borderWidth: 1, borderColor: "#ccc", borderRadius: 10, padding: 12 }}
      />

      {!verificationId ? (
        <Pressable onPress={send} style={{ backgroundColor: "black", padding: 12, borderRadius: 10 }}>
          <Text style={{ color: "white", textAlign: "center", fontWeight: "700" }}>{t("sendOtp")}</Text>
        </Pressable>
      ) : (
        <>
          <TextInput
            placeholder={t("otp")}
            value={code}
            onChangeText={setCode}
            keyboardType="number-pad"
            style={{ borderWidth: 1, borderColor: "#ccc", borderRadius: 10, padding: 12 }}
          />
          <Pressable onPress={verify} style={{ backgroundColor: "black", padding: 12, borderRadius: 10 }}>
            <Text style={{ color: "white", textAlign: "center", fontWeight: "700" }}>{t("verify")}</Text>
          </Pressable>
        </>
      )}
    </View>
  );
}
