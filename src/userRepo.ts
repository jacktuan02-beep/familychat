import { doc, getDoc, setDoc, serverTimestamp } from "firebase/firestore";
import { db } from "./firebase";

let ME_PHONE = "";

export async function upsertUserByPhone(phone: string) {
  ME_PHONE = phone;
  const ref = doc(db, "users", phone);
  await setDoc(ref, {
    phone,
    displayName: phone,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp()
  }, { merge: true });
}

export async function getMe() {
  if (!ME_PHONE) throw new Error("Chưa đăng nhập");
  return { phone: ME_PHONE };
}

export async function findUserByPhone(phone: string) {
  const ref = doc(db, "users", phone);
  const snap = await getDoc(ref);
  if (!snap.exists()) return null;
  return snap.data() as { phone: string; displayName: string };
}

export async function createDirectChat(mePhone: string, otherPhone: string) {
  const [a, b] = [mePhone, otherPhone].sort();
  const chatId = `dm_${a}_${b}`;
  const ref = doc(db, "chats", chatId);
  await setDoc(ref, {
    type: "dm",
    members: [a, b],
    updatedAt: serverTimestamp()
  }, { merge: true });
  return chatId;
}
