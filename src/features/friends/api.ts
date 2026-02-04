import { db } from "../../lib/firebase";
import { doc, getDoc, setDoc, query, where, collection, getDocs } from "firebase/firestore";

export async function upsertProfile(uid: string, phone: string) {
  const ref = doc(db, "users", uid);
  await setDoc(ref, { uid, phone, createdAt: Date.now() }, { merge: true });
}

export async function findUserByPhone(phone: string) {
  const q = query(collection(db, "users"), where("phone", "==", phone));
  const snap = await getDocs(q);
  if (snap.empty) return null;
  const d = snap.docs[0].data() as any;
  return { uid: d.uid as string, phone: d.phone as string };
}

export async function addFriend(myUid: string, otherUid: string) {
  await setDoc(doc(db, "friends", `${myUid}_${otherUid}`), { a: myUid, b: otherUid, createdAt: Date.now() }, { merge: true });
  await setDoc(doc(db, "friends", `${otherUid}_${myUid}`), { a: otherUid, b: myUid, createdAt: Date.now() }, { merge: true });
}

export async function listFriends(myUid: string) {
  const q = query(collection(db, "friends"), where("a", "==", myUid));
  const snap = await getDocs(q);
  return snap.docs.map(d => (d.data() as any).b as string);
}

export async function getUser(uid: string) {
  const ref = doc(db, "users", uid);
  const snap = await getDoc(ref);
  return snap.exists() ? (snap.data() as any) : null;
}
