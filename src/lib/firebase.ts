import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
    apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
    authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
    storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

// 빌드 시점에 API Key가 없어도 에러가 나지 않도록 방어 처리
const app = (typeof window !== "undefined" || process.env.NEXT_PUBLIC_FIREBASE_API_KEY)
    ? (getApps().length > 0 ? getApp() : initializeApp(firebaseConfig))
    : null;

const auth = (app ? getAuth(app) : null) as any;
const db = (app ? getFirestore(app) : null) as any;
const googleProvider = new GoogleAuthProvider();

export { auth, db, app, googleProvider };
