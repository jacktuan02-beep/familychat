import {
  collection, doc, getDoc, onSnapshot, orderBy, query, setDoc, addDoc, serverTimestamp, where, getDocs
} from "firebase/firestore";
import { db } from "./firebase";

export async function getChatTitle(chatId: string, mePhone: string) {
  const ref = doc(db, "chats", chatId);
  const snap = await getDoc(ref);
  if (!snap.exists()) return "Chat";
  const data = snap.data() as any;
  if (data.type === "dm") {
    const other = (data.members || []).find((x: string) => x !== mePhone) || "Bạn";
    return other;
  }
  return data.title || "Nhóm";
}

export function listenMessages(chatId: string, cb: (items: any[]) => void) {
  const q = query(collection(db, "chats", chatId, "messages"), orderBy("ts", "desc"));
  return onSnapshot(q, (snap) => {
    const items = snap.docs.map((d) => {
      const v = d.data() as any;
      return { id: d.id, from: v.from, text: v.text, ts: v.ts?.toMillis?.() ?? 0 };
    });
    cb(items);
  });
}

export async function sendMessage(chatId: string, from: string, text: string) {
  await addDoc(collection(db, "chats", chatId, "messages"), {
    from,
    text,
    ts: serverTimestamp()
  });
  await setDoc(doc(db, "chats", chatId), { updatedAt: serverTimestamp() }, { merge: true });
}

export async function listMyChats(mePhone: string) {
  const q = query(collection(db, "chats"), where("members", "array-contains", mePhone));
  const snap = await getDocs(q);
  return snap.docs.map((d) => {
    const v = d.data() as any;
    let title = d.id;
    if (v.type === "dm") {
      const other = (v.members || []).find((x: string) => x !== mePhone) || "Bạn";
      title = other;
    } else if (v.type === "group") {
      title = v.title || "Nhóm";
    }
    return { id: d.id, title };
  });
}
