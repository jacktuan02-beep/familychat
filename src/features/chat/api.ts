import { db } from "../../lib/firebase";
import { collection, doc, getDoc, setDoc, addDoc, query, where, orderBy, limit, onSnapshot } from "firebase/firestore";

function dmId(a: string, b: string) {
  return [a, b].sort().join("_");
}

export async function ensureDM(a: string, b: string) {
  const id = dmId(a, b);
  const ref = doc(db, "chats", id);
  const snap = await getDoc(ref);
  if (!snap.exists()) {
    await setDoc(ref, { id, kind: "dm", memberUids: [a, b], createdAt: Date.now(), updatedAt: Date.now() });
  }
  return id;
}

export async function sendText(chatId: string, fromUid: string, text: string) {
  await addDoc(collection(db, "chats", chatId, "messages"), { chatId, fromUid, type: "text", text, createdAt: Date.now() });
  await setDoc(doc(db, "chats", chatId), { updatedAt: Date.now(), lastMessage: { text, at: Date.now() } }, { merge: true });
}

export function subscribeMessages(chatId: string, cb: (msgs: any[]) => void) {
  const q = query(collection(db, "chats", chatId, "messages"), orderBy("createdAt", "asc"), limit(200));
  return onSnapshot(q, (snap) => cb(snap.docs.map(d => ({ id: d.id, ...d.data() }))));
}

export function subscribeMyChats(myUid: string, cb: (rows: any[]) => void) {
  const q = query(collection(db, "chats"), where("memberUids", "array-contains", myUid), orderBy("updatedAt", "desc"), limit(50));
  return onSnapshot(q, (snap) => cb(snap.docs.map(d => d.data() as any)));
}
