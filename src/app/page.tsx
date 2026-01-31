"use client";

import React, { useState, useEffect, useRef } from 'react';
import {
  Users,
  Calendar,
  MessageSquare,
  Settings,
  Plus,
  Search,
  Download,
  Upload,
  Clock,
  X,
  Mic,
  MicOff,
  Loader2,
  ChevronRight,
  ChevronLeft,
  CalendarCheck,
  History,
  Sparkles,
  Mail,
  ShieldCheck,
  FileText,
  ExternalLink,
  LogOut,
  Trash2,
  MoreVertical
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  signInWithPopup,
  onAuthStateChanged,
  signOut,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  updateProfile
} from 'firebase/auth';
import {
  collection,
  addDoc,
  onSnapshot,
  deleteDoc,
  doc,
  updateDoc
} from 'firebase/firestore';
import { auth, db, googleProvider } from '@/lib/firebase';
import { cn } from '@/lib/utils';

// Shadcn UI Components
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import {
  Avatar,
  AvatarFallback,
  AvatarImage,
} from "@/components/ui/avatar";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

// --- Branding Component ---
const LogBLogo = ({ variant = 'symbol', className = "" }: { variant?: 'symbol' | 'horizontal' | 'vertical', className?: string }) => {
  const symbol = (
    <svg viewBox="0 0 100 100" className="w-full h-full" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="grad_blue_icon" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#4F46E5" />
          <stop offset="100%" stopColor="#2563EB" />
        </linearGradient>
      </defs>
      <rect width="100" height="100" rx="28" fill="url(#grad_blue_icon)" />
      <g transform="translate(12.625, 12.625) scale(0.65)">
        <path
          d="M35 25V75M48 25H58C68 25 75 32 75 40C75 48 68 55 58 55M48 55H62C72 55 80 62 80 72C80 82 72 90 62 90"
          stroke="white"
          strokeWidth="11"
          strokeLinecap="round"
          fill="none"
        />
      </g>
    </svg>
  );

  if (variant === 'symbol') return <div className={className}>{symbol}</div>;

  if (variant === 'horizontal') {
    return (
      <div className={cn("flex items-center gap-2", className)}>
        <div className="w-8 h-8 shrink-0">{symbol}</div>
        <div className="flex flex-col">
          <h1 className="text-lg font-bold leading-none tracking-tight text-slate-900 flex items-center">
            Log<span className="text-primary mx-0.5">:</span>B
          </h1>
          <p className="text-[7px] font-bold text-slate-400 uppercase tracking-widest leading-none mt-1">Log Business</p>
        </div>
      </div>
    );
  }

  if (variant === 'vertical') {
    return (
      <div className={cn("flex flex-col items-center text-center", className)}>
        <div className="w-20 h-20 mb-6 rounded-3xl overflow-hidden shadow-sm">{symbol}</div>
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 mb-1">
          Log<span className="text-blue-600">:</span>B
        </h1>
        <p className="text-[10px] font-bold text-slate-400 uppercase tracking-[0.3em]">
          Log Business
        </p>
      </div>
    );
  }

  return null;
};

// --- Models ---
interface Contact {
  id: string;
  name: string;
  company: string;
  position?: string;
  phone?: string;
  email?: string;
  tags?: string[];
  nextSchedule?: string;
  createdAt: string;
}

interface Meeting {
  id: string;
  contactId: string;
  contactName: string;
  date: string;
  location?: string;
  content: string;
  aiSummary?: {
    peer_briefing: string;
    vibe_check: string;
    next_action_tips: string[];
    cheering_message: string;
  };
  nextSchedule?: string;
  createdAt: string;
}

// --- Main Application ---
export default function App() {
  const [user, setUser] = useState<any>(null);
  const [activeTab, setActiveTab] = useState('contacts');
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [meetings, setMeetings] = useState<Meeting[]>([]);
  const [searchQuery, setSearchQuery] = useState('');

  const [isContactModalOpen, setIsContactModalOpen] = useState(false);
  const [isMeetingModalOpen, setIsMeetingModalOpen] = useState(false);
  const [isScheduleModalOpen, setIsScheduleModalOpen] = useState(false);
  const [selectedContactId, setSelectedContactId] = useState<string | null>(null);
  const [newContactData, setNewContactData] = useState({ name: '', phone: '', email: '' });
  const [scheduleView, setScheduleView] = useState<'card' | 'calendar'>('card');

  const [isListening, setIsListening] = useState(false);
  const [meetingContent, setMeetingContent] = useState("");
  const [isAiGenerating, setIsAiGenerating] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const appId = "log-b-mvp";
  const geminiApiKey = process.env.NEXT_PUBLIC_GEMINI_API_KEY;

  const [isLoading, setIsLoading] = useState(true);
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
  const [authMode, setAuthMode] = useState<'login' | 'signup'>('login');
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [authError, setAuthError] = useState("");

  const [isTermsOpen, setIsTermsOpen] = useState(false);
  const [isPrivacyOpen, setIsPrivacyOpen] = useState(false);

  // 1. Authentication
  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (user) => {
      setUser(user);
      setIsLoading(false);
    });
    return () => unsub();
  }, []);

  const handleGoogleLogin = async () => {
    try {
      await signInWithPopup(auth, googleProvider);
      setIsAuthModalOpen(false);
    } catch (err: any) {
      setAuthError(err.message);
    }
  };

  const handleEmailAuth = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError("");
    try {
      if (authMode === 'login') {
        await signInWithEmailAndPassword(auth, email, password);
      } else {
        const cred = await createUserWithEmailAndPassword(auth, email, password);
        await updateProfile(cred.user, { displayName: name });
      }
      setIsAuthModalOpen(false);
    } catch (err: any) {
      setAuthError(err.message);
    }
  };

  // 2. Data Subscription
  useEffect(() => {
    if (!user) return;

    const contactsRef = collection(db, 'artifacts', appId, 'users', user.uid, 'contacts');
    const unsubContacts = onSnapshot(contactsRef, (snap) => {
      setContacts(snap.docs.map(d => ({ id: d.id, ...d.data() } as Contact)));
    }, (err) => console.error("Firestore Error:", err));

    const meetingsRef = collection(db, 'artifacts', appId, 'users', user.uid, 'meetings');
    const unsubMeetings = onSnapshot(meetingsRef, (snap) => {
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() } as Meeting));
      setMeetings(data.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()));
    }, (err) => console.error("Firestore Error:", err));

    return () => { unsubContacts(); unsubMeetings(); };
  }, [user]);

  // --- AI Logic ---
  const generateAiPeerSummary = async (content: string, contactName: string) => {
    const systemPrompt = `너는 유능하고 친절한 영업 사수 '로그비'야. 사용자와 함께 발로 뛰는 동료로서 미팅 내용을 정리해줘.
    [응답 원칙]
    1. 톤앤매너: 친근한 구어체 사용.
    2. 공감과 응원: 미팅의 고생을 알아주고 응원 메시지 포함.
    3. 핵심 요약: 중요한 내용은 맨 앞에.
    4. 실행 중심: 다음에 바로 해야 할 구체적인 팁 제안.
    출력 형식: JSON (peer_briefing, vibe_check, next_action_tips[], cheering_message)`;

    try {
      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=${geminiApiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: `거래처: ${contactName}, 미팅내용: ${content}` }] }],
          systemInstruction: { parts: [{ text: systemPrompt }] },
          generationConfig: { responseMimeType: "application/json" }
        })
      });
      const result = await response.json();
      return JSON.parse(result.candidates?.[0]?.content?.parts?.[0]?.text || "{}");
    } catch (e) {
      console.error("AI Error:", e);
      return null;
    }
  };

  const handleSaveContact = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!user) return;
    const fd = new FormData(e.currentTarget);
    const data = {
      name: fd.get('name'),
      company: fd.get('company'),
      position: fd.get('position'),
      phone: fd.get('phone'),
      email: fd.get('email'),
      tags: fd.get('tags')?.toString().split(',').map(t => t.trim()).filter(t => t) || [],
      createdAt: new Date().toISOString()
    };
    await addDoc(collection(db, 'artifacts', appId, 'users', user.uid, 'contacts'), data);
    setIsContactModalOpen(false);
  };

  const handleSaveMeeting = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!user || isAiGenerating) return;
    const fd = new FormData(e.currentTarget);
    const contact = contacts.find(c => c.id === fd.get('contactId'));

    setIsAiGenerating(true);
    const aiSummary = await generateAiPeerSummary(meetingContent, contact?.name || "알 수 없음");

    const newMeeting = {
      contactId: fd.get('contactId'), contactName: contact?.name || 'Unknown',
      date: fd.get('date'), location: fd.get('location'), content: meetingContent,
      aiSummary: aiSummary, nextSchedule: fd.get('nextSchedule') || '',
      createdAt: new Date().toISOString()
    };

    await addDoc(collection(db, 'artifacts', appId, 'users', user.uid, 'meetings'), newMeeting);
    if (newMeeting.nextSchedule && contact) {
      await updateDoc(doc(db, 'artifacts', appId, 'users', user.uid, 'contacts', contact.id), { nextSchedule: newMeeting.nextSchedule });
    }

    setIsAiGenerating(false);
    setIsMeetingModalOpen(false);
    setMeetingContent("");
  };

  const handleSaveSchedule = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!user) return;
    const fd = new FormData(e.currentTarget);
    const contactId = fd.get('contactId') as string;
    const date = fd.get('date') as string;

    if (contactId && date) {
      await updateDoc(doc(db, 'artifacts', appId, 'users', user.uid, 'contacts', contactId), { nextSchedule: date });
      setIsScheduleModalOpen(false);
    }
  };

  const handleImportContacts = async () => {
    try {
      const props = ['name', 'tel', 'email'];
      const opts = { multiple: false };
      const supported = 'contacts' in navigator && 'select' in (navigator as any).contacts;

      if (!supported) {
        alert("현재 사용 중인 브라우저/OS에서 연락처 가져오기 기능을 지원하지 않습니다.\n\n지원 환경:\n· 안드로이드 (Chrome, Edge 등)\n· iOS (현재 브라우저 기술 제약으로 미지원)\n· HTTPS 보안 연결 환경\n\n거래처 정보를 직접 입력해 주세요.");
        return;
      }

      const contacts_picked = await (navigator as any).contacts.select(props, opts);
      if (contacts_picked.length > 0) {
        const c = contacts_picked[0];
        setNewContactData({
          name: c.name?.[0] || '',
          phone: c.tel?.[0] || '',
          email: c.email?.[0] || ''
        });
      }
    } catch (err) {
      console.error("Contact Picker Error:", err);
    }
  };

  const toggleSTT = () => {
    const SpeechRecognition = (window as any).webkitSpeechRecognition || (window as any).SpeechRecognition;
    if (!SpeechRecognition) return;
    if (isListening) { setIsListening(false); return; }
    const recognition = new SpeechRecognition();
    recognition.lang = 'ko-KR';
    recognition.onstart = () => setIsListening(true);
    recognition.onend = () => setIsListening(false);
    recognition.onresult = (e: any) => setMeetingContent(p => p + " " + e.results[0][0].transcript);
    recognition.start();
  };

  const downloadCSV = (data: any[], filename: string) => {
    if (data.length === 0) return;
    const headers = Object.keys(data[0]).join(',');
    const rows = data.map(obj => Object.values(obj).map(val => `"${val}"`).join(',')).join('\n');
    const csvContent = `${headers}\n${rows}`;
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.setAttribute("download", `${filename}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleClearSchedule = async (contactId: string) => {
    if (!user) return;
    await updateDoc(doc(db, 'artifacts', appId, 'users', user.uid, 'contacts', contactId), { nextSchedule: '' });
  };

  const filteredContacts = contacts.filter(c =>
    c.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.company?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (c.tags && c.tags.some(tag => tag.toLowerCase().includes(searchQuery.toLowerCase())))
  );

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <Loader2 className="animate-spin text-primary w-8 h-8" />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="h-full overflow-y-auto app-scroll-area bg-slate-50 relative overflow-x-hidden">
        <div className="min-h-[100dvh] flex flex-col">
          <div className="flex-1 flex flex-col items-center justify-center p-6 sm:p-12 relative">
            {/* Subtle decorative elements */}
            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-blue-600 via-indigo-600 to-primary opacity-20" />

            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="flex flex-col items-center z-10 space-y-8 w-full max-w-sm"
            >
              <LogBLogo variant="vertical" />

              <div className="space-y-4 text-center max-w-sm">
                <p className="text-sm font-medium text-slate-500 leading-relaxed font-pretendard">
                  성공하는 비즈니스의 시작, <br />
                  완벽한 기록과 AI 통찰로 성장을 관리하세요.
                </p>
              </div>

              <Button
                size="lg"
                className="rounded-full px-12 h-14 text-base font-bold shadow-xl shadow-primary/20 transition-all hover:scale-105 active:scale-95"
                onClick={() => setIsAuthModalOpen(true)}
              >
                시작하기
              </Button>

              <p className="text-[10px] font-bold text-slate-300 uppercase tracking-widest pt-8">
                NEXTIDEALAB PROJECT#2
              </p>
            </motion.div>

            {/* Auth Dialog */}
            <Dialog open={isAuthModalOpen} onOpenChange={setIsAuthModalOpen}>
              <DialogContent className="sm:max-w-md rounded-[32px] p-8">
                <DialogHeader className="space-y-3 mb-6">
                  <LogBLogo variant="symbol" className="w-10 h-10 mb-2" />
                  <DialogTitle className="text-2xl font-bold tracking-tight">
                    {authMode === 'login' ? '환영합니다' : '계정 생성'}
                  </DialogTitle>
                  <DialogDescription className="text-slate-500 font-medium">
                    {authMode === 'login' ? '본인 확인 후 서비스를 계속하세요' : '로그비와 함께 스마트한 비즈니스를 시작하세요'}
                  </DialogDescription>
                </DialogHeader>

                <div className="space-y-6">
                  <Button
                    variant="outline"
                    className="w-full h-12 rounded-xl font-bold gap-3 border-slate-200"
                    onClick={handleGoogleLogin}
                  >
                    <svg className="w-5 h-5" viewBox="0 0 24 24">
                      <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4" />
                      <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
                      <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05" />
                      <path d="M12 5.38c1.62 0 3.06.56 4.21 1.66l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" />
                    </svg>
                    Google로 계속하기
                  </Button>

                  <div className="relative">
                    <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-slate-100" /></div>
                    <div className="relative flex justify-center text-[10px] uppercase font-bold text-slate-300 bg-white px-2">OR</div>
                  </div>

                  <form onSubmit={handleEmailAuth} className="space-y-3">
                    {authMode === 'signup' && (
                      <Input
                        required placeholder="이름" value={name} onChange={e => setName(e.target.value)}
                        className="h-12 rounded-xl bg-slate-50 border-none font-bold"
                      />
                    )}
                    <Input
                      required type="email" placeholder="이메일" value={email} onChange={e => setEmail(e.target.value)}
                      className="h-12 rounded-xl bg-slate-50 border-none font-bold"
                    />
                    <Input
                      required type="password" placeholder="비밀번호" value={password} onChange={e => setPassword(e.target.value)}
                      className="h-12 rounded-xl bg-slate-50 border-none font-bold"
                    />
                    {authError && <p className="text-[10px] font-bold text-destructive text-center">{authError}</p>}
                    <Button type="submit" className="w-full h-12 rounded-xl font-bold shadow-lg shadow-primary/10 transition-all active:scale-95">
                      {authMode === 'login' ? '로그인' : '가입하기'}
                    </Button>
                  </form>

                  <div className="text-center pt-2">
                    <Button
                      variant="ghost" size="sm"
                      className="text-slate-400 font-bold text-[11px] hover:text-primary"
                      onClick={() => setAuthMode(authMode === 'login' ? 'signup' : 'login')}
                    >
                      {authMode === 'login' ? '새 계정이 필요하신가요?' : '이미 계정이 있으신가요?'}
                    </Button>
                  </div>
                </div>
              </DialogContent>
            </Dialog>
          </div>
          <Footer onOpenTerms={() => setIsTermsOpen(true)} onOpenPrivacy={() => setIsPrivacyOpen(true)} />
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full bg-[#FDFDFD] font-pretendard selection:bg-primary/10 no-select">
      {/* Navbar */}
      <header className="fixed top-0 z-40 w-full bg-white/70 backdrop-blur-xl border-b border-slate-100 safe-top">
        <div className="max-w-screen-xl mx-auto px-4 sm:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center cursor-pointer" onClick={() => setActiveTab('contacts')}>
            <LogBLogo variant="horizontal" />
          </div>

          <div className="hidden md:flex items-center gap-1">
            {[
              { id: 'contacts', icon: Users, label: '인맥 관리' },
              { id: 'schedule', icon: CalendarCheck, label: '통합 일정' },
              { id: 'meetings', icon: MessageSquare, label: '리포트' },
            ].map(item => (
              <Button
                key={item.id}
                variant={activeTab === item.id ? "secondary" : "ghost"}
                size="sm"
                onClick={() => setActiveTab(item.id)}
                className={cn(
                  "rounded-full px-4 font-bold transition-all",
                  activeTab === item.id ? "bg-slate-100 text-slate-900" : "text-slate-400"
                )}
              >
                {item.label}
              </Button>
            ))}
          </div>


          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" className="rounded-full">
                <Avatar className="w-8 h-8">
                  <AvatarImage src={user?.photoURL} />
                  <AvatarFallback className="bg-primary/5 text-primary text-[10px] font-bold">{user?.displayName?.[0] || 'U'}</AvatarFallback>
                </Avatar>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="rounded-xl w-48 shadow-xl border-slate-100">
              <DropdownMenuItem className="text-xs font-bold py-3 text-slate-500 cursor-default">
                {user?.email}
              </DropdownMenuItem>
              <DropdownMenuItem
                onClick={() => setActiveTab('settings')}
                className="font-bold text-xs py-3 cursor-pointer"
              >
                <Settings className="w-4 h-4 mr-2" /> 설정
              </DropdownMenuItem>
              <DropdownMenuItem
                onClick={() => signOut(auth)}
                className="font-bold text-xs py-3 cursor-pointer text-destructive focus:text-destructive"
              >
                <LogOut className="w-4 h-4 mr-2" /> 로그아웃
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </header>

      {/* Main Content Area - Scrollable */}
      <main className="app-scroll-area pt-16 pb-32 md:pb-8">
        <div className="max-w-screen-xl mx-auto px-4 sm:px-8 py-8 sm:py-12">

          {/* Dashboard Grid */}
          <section className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-10">
            <StatCard
              label="총 파트너" value={contacts.length} icon={<Users />}
              active={activeTab === 'contacts'} onClick={() => setActiveTab('contacts')}
              action={
                <Button
                  size="xs"
                  className="rounded-full h-8 px-3 font-bold shadow-sm"
                  onClick={(e) => {
                    e.stopPropagation();
                    setNewContactData({ name: '', phone: '', email: '' });
                    setIsContactModalOpen(true);
                  }}
                >
                  <Plus className="w-3 h-3 mr-1" strokeWidth={3} /> 거래처 추가
                </Button>
              }
            />
            <StatCard
              label="남은 일정" value={contacts.filter(c => c.nextSchedule).length} icon={<CalendarCheck />}
              active={activeTab === 'schedule'} onClick={() => setActiveTab('schedule')}
              action={
                <Button
                  size="xs" variant="outline"
                  className="rounded-full h-8 px-3 font-bold border-slate-200 shadow-sm"
                  onClick={(e) => {
                    e.stopPropagation();
                    setSelectedContactId(null);
                    setIsScheduleModalOpen(true);
                  }}
                >
                  <Plus className="w-3 h-3 mr-1" strokeWidth={3} /> 일정 등록
                </Button>
              }
            />
            <StatCard
              label="기록된 로그" value={meetings.length} icon={<MessageSquare />}
              active={activeTab === 'meetings'} onClick={() => setActiveTab('meetings')}
              action={
                <Button
                  size="xs" variant="secondary"
                  className="rounded-full h-8 px-3 font-bold bg-slate-800 text-white hover:bg-slate-900 shadow-sm"
                  onClick={(e) => {
                    e.stopPropagation();
                    setSelectedContactId(null);
                    setMeetingContent("");
                    setIsMeetingModalOpen(true);
                  }}
                >
                  <Plus className="w-3 h-3 mr-1" strokeWidth={3} /> 로그 기록
                </Button>
              }
            />
          </section>

          <div className="flex flex-col lg:flex-row gap-10">
            {/* Sidebar */}
            <aside className="lg:w-72 shrink-0 space-y-6">
              <Card className="rounded-3xl border-slate-100 shadow-sm overflow-hidden">
                <CardHeader className="pb-4">
                  <CardTitle className="text-xs font-bold text-slate-400 uppercase tracking-widest leading-none">검색 필터</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-300 w-4 h-4" />
                    <Input
                      value={searchQuery} onChange={e => setSearchQuery(e.target.value)}
                      placeholder="이름, 거래처, 태그..."
                      className="pl-9 h-10 rounded-xl bg-slate-50 border-none text-xs font-medium"
                    />
                  </div>
                  <div className="flex flex-wrap gap-1.5 pt-2">
                    {['#중요', '#VIP', '#Potential'].map(tag => (
                      <Badge
                        key={tag} variant="outline"
                        className="rounded-lg px-2 py-0.5 text-[9px] font-bold cursor-pointer hover:bg-primary/5 hover:text-primary transition-colors border-slate-200"
                        onClick={() => setSearchQuery(tag.replace('#', ''))}
                      >
                        {tag}
                      </Badge>
                    ))}
                  </div>
                </CardContent>
              </Card>

              <Card className="hidden md:block rounded-3xl border-slate-100 shadow-sm">
                <CardHeader className="pb-4">
                  <CardTitle className="text-xs font-bold text-slate-400 uppercase tracking-widest leading-none">데이터 도구</CardTitle>
                </CardHeader>
                <CardContent className="grid grid-cols-2 gap-2">
                  <Button
                    variant="outline" size="sm" className="rounded-xl h-20 flex-col gap-2 font-bold text-[10px] border-slate-100"
                    onClick={() => fileInputRef.current?.click()}
                  >
                    <Upload className="w-5 h-5 text-slate-400" /> 가져오기
                  </Button>
                  <Button
                    variant="outline" size="sm" className="rounded-xl h-20 flex-col gap-2 font-bold text-[10px] border-slate-100"
                    onClick={() => downloadCSV(contacts, 'LogB_Data')}
                  >
                    <Download className="w-5 h-5 text-slate-400" /> 내보내기
                  </Button>
                  <input type="file" ref={fileInputRef} className="hidden" />
                </CardContent>
              </Card>
            </aside>

            {/* View Container */}
            <div className="flex-1">
              <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
                <TabsContent value="contacts" className="mt-0 space-y-4 animate-in fade-in duration-500">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {filteredContacts.length === 0 ? (
                      <Card className="col-span-full border-dashed p-12 flex flex-col items-center text-center space-y-4 rounded-3xl">
                        <Users className="w-12 h-12 text-slate-200" />
                        <div className="space-y-1">
                          <p className="text-slate-500 font-bold">검색 결과가 없거나 등록된 거래처가 없습니다.</p>
                          <p className="text-slate-300 text-xs font-medium">새로운 비즈니스 인연을 기록해 보세요.</p>
                        </div>
                        <Button variant="outline" size="sm" onClick={() => setIsContactModalOpen(true)} className="rounded-full">
                          첫 거래처 등록
                        </Button>
                      </Card>
                    ) : (
                      filteredContacts.map(c => (
                        <ContactCard
                          key={c.id} contact={c}
                          onAddLog={() => { setSelectedContactId(c.id); setIsMeetingModalOpen(true); }}
                          onDelete={() => deleteDoc(doc(db, 'artifacts', appId, 'users', user.uid, 'contacts', c.id))}
                        />
                      ))
                    )}
                  </div>
                </TabsContent>

                <TabsContent value="schedule" className="mt-0 space-y-6 animate-in fade-in duration-500">
                  <div className="flex items-center justify-between px-2">
                    <div className="flex items-center gap-3">
                      < CalendarCheck className="text-primary w-5 h-5" />
                      <h3 className="text-lg font-bold tracking-tight">전략적 예정 일정</h3>
                    </div>
                    <div className="bg-slate-100 p-1 rounded-xl flex gap-1">
                      <Button
                        variant={scheduleView === 'card' ? 'default' : 'ghost'}
                        size="sm" className={cn("h-8 rounded-lg text-[10px] font-bold px-3", scheduleView === 'card' && "shadow-sm bg-white text-slate-900 hover:bg-white")}
                        onClick={() => setScheduleView('card')}
                      >
                        리스트
                      </Button>
                      <Button
                        variant={scheduleView === 'calendar' ? 'default' : 'ghost'}
                        size="sm" className={cn("h-8 rounded-lg text-[10px] font-bold px-3", scheduleView === 'calendar' && "shadow-sm bg-white text-slate-900 hover:bg-white")}
                        onClick={() => setScheduleView('calendar')}
                      >
                        캘린더
                      </Button>
                    </div>
                  </div>

                  {scheduleView === 'card' ? (
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      {contacts.filter(c => c.nextSchedule).length === 0 ? (
                        <p className="col-span-full py-12 text-center text-slate-400 text-sm font-medium border border-dashed rounded-3xl">예정된 일정이 없습니다.</p>
                      ) : (
                        contacts.filter(c => c.nextSchedule)
                          .sort((a, b) => new Date(a.nextSchedule!).getTime() - new Date(b.nextSchedule!).getTime())
                          .map(c => (
                            <Card key={c.id} className="rounded-3xl border-l-[6px] border-l-primary shadow-sm hover:shadow-md transition-shadow transition-transform">
                              <CardContent className="p-5 flex items-center gap-4">
                                <div className="w-12 h-12 rounded-2xl bg-primary/5 flex flex-col items-center justify-center text-primary border border-primary/10 shrink-0">
                                  <span className="text-[8px] font-bold uppercase">D-Day</span>
                                  <span className="text-lg font-bold leading-none">{c.nextSchedule?.split('-')[2]}</span>
                                </div>
                                <div className="flex-1 overflow-hidden">
                                  <h4 className="font-bold text-slate-900 truncate">{c.name}님</h4>
                                  <p className="text-[10px] text-slate-400 font-bold uppercase tracking-tight truncate">{c.company}</p>
                                </div>
                                <div className="flex items-center gap-1">
                                  <Button size="icon" variant="ghost" className="rounded-full w-8 h-8 text-slate-300 hover:text-destructive hover:bg-destructive/10 transition-colors" onClick={() => handleClearSchedule(c.id)}>
                                    <Trash2 className="w-4 h-4" />
                                  </Button>
                                  <Button size="icon" variant="ghost" className="rounded-full w-8 h-8 hover:bg-primary/10 hover:text-primary transition-colors" onClick={() => { setSelectedContactId(c.id); setIsMeetingModalOpen(true); }}>
                                    <Plus className="w-4 h-4" />
                                  </Button>
                                </div>
                              </CardContent>
                            </Card>
                          ))
                      )}
                    </div>
                  ) : (
                    <CalendarView contacts={contacts} />
                  )}
                </TabsContent>

                <TabsContent value="meetings" className="mt-0 space-y-4 animate-in fade-in duration-500">
                  {meetings.length === 0 ? (
                    <div className="py-20 text-center border border-dashed rounded-3xl">
                      <p className="text-slate-400 text-sm font-bold">생성된 AI 리포트가 없습니다.</p>
                    </div>
                  ) : (
                    meetings.map(m => (
                      <MeetingCard key={m.id} meeting={m} onDelete={() => deleteDoc(doc(db, 'artifacts', appId, 'users', user.uid, 'meetings', m.id))} />
                    ))
                  )}
                </TabsContent>

                <TabsContent value="settings" className="mt-0 animate-in fade-in duration-500">
                  <Card className="rounded-[40px] border-slate-100 shadow-xl overflow-hidden max-w-xl mx-auto py-12">
                    <CardContent className="flex flex-col items-center space-y-10">
                      <LogBLogo variant="vertical" />
                      <div className="w-full space-y-3">
                        <div className="bg-slate-50 p-4 rounded-2xl flex justify-between items-center">
                          <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest leading-none">Account</span>
                          <span className="text-xs font-bold text-slate-900">{user?.email}</span>
                        </div>
                        <div className="bg-slate-50 p-4 rounded-2xl flex justify-between items-center">
                          <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest leading-none">Sync Status</span>
                          <Badge variant="outline" className="text-[9px] font-bold border-emerald-200 text-emerald-600 bg-emerald-50">Active Protective</Badge>
                        </div>
                      </div>
                      <Button
                        variant="destructive"
                        size="lg"
                        className="w-full rounded-2xl font-bold transition-all shadow-lg shadow-destructive/10"
                        onClick={() => signOut(auth)}
                      >
                        안전하게 세션 종료
                      </Button>
                    </CardContent>
                  </Card>

                  {/* Mobile Footer integrated in Settings tab */}
                  <div className="md:hidden mt-20 mb-12">
                    <Footer onOpenTerms={() => setIsTermsOpen(true)} onOpenPrivacy={() => setIsPrivacyOpen(true)} />
                  </div>
                </TabsContent>
              </Tabs>
            </div>
          </div>
        </div>
      </main>

      {/* Floating Mobile Nav */}
      <nav className="md:hidden fixed bottom-4 left-1/2 -translate-x-1/2 w-[95%] max-w-sm bg-slate-900/95 backdrop-blur-xl border border-white/10 rounded-[32px] shadow-2xl p-2 px-4 pb-[calc(0.5rem+env(safe-area-inset-bottom))] flex justify-between items-center z-50">
        {
          [
            { id: 'contacts', icon: Users, label: '인맥' },
            { id: 'schedule', icon: CalendarCheck, label: '일정' },
            { id: 'meetings', icon: MessageSquare, label: '리포트' },
            { id: 'settings', icon: Settings, label: '설정' },
          ].map(item => (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={cn(
                "flex flex-col items-center justify-center gap-1 transition-all py-1.5 px-3 rounded-2xl",
                activeTab === item.id ? "bg-white text-slate-900 scale-105 shadow-lg" : "text-white/40"
              )}
            >
              <item.icon className={cn("w-5 h-5", activeTab === item.id ? "stroke-[2.5px]" : "stroke-[2px]")} />
              <span className="text-[10px] font-bold tracking-tight">{item.label}</span>
            </button>
          ))
        }
      </nav>

      {/* Desktop Dashboard Footer */}
      <div className="hidden md:block">
        <Footer onOpenTerms={() => setIsTermsOpen(true)} onOpenPrivacy={() => setIsPrivacyOpen(true)} />
      </div>

      <LegalModals
        isTermsOpen={isTermsOpen}
        setIsTermsOpen={setIsTermsOpen}
        isPrivacyOpen={isPrivacyOpen}
        setIsPrivacyOpen={setIsPrivacyOpen}
      />

      {/* Modals */}
      <Dialog open={isContactModalOpen} onOpenChange={setIsContactModalOpen}>
        <DialogContent className="sm:max-w-xl rounded-[32px] p-8 max-h-[90vh] overflow-y-auto">
          <DialogHeader className="mb-6">
            <div className="flex justify-between items-center">
              <DialogTitle className="text-2xl font-bold tracking-tight italic">새 인맥 등록</DialogTitle>
              <Button type="button" variant="outline" size="sm" onClick={handleImportContacts} className="rounded-full text-[10px] font-bold h-8">
                <Upload className="w-3 h-3 mr-1" /> 연락처 가져오기
              </Button>
            </div>
            <DialogDescription className="font-medium">기본 인적사항 및 특징을 기록해 두세요.</DialogDescription>
          </DialogHeader>
          <form onSubmit={handleSaveContact} className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">성명</label>
                <Input required name="name" value={newContactData.name} onChange={e => setNewContactData({ ...newContactData, name: e.target.value })} className="h-12 rounded-xl bg-slate-50 border-none font-bold" />
              </div>
              <div className="space-y-2">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">회사/기관</label>
                <Input required name="company" className="h-12 rounded-xl bg-slate-50 border-none font-bold" />
              </div>
            </div>
            <div className="space-y-2">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">부서 / 직책</label>
              <Input name="position" className="h-12 rounded-xl bg-slate-50 border-none font-bold" />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">대표 번호</label>
                <Input name="phone" placeholder="010-" value={newContactData.phone} onChange={e => setNewContactData({ ...newContactData, phone: e.target.value })} className="h-12 rounded-xl bg-slate-50 border-none font-bold text-sm" />
              </div>
              <div className="space-y-2">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">이메일</label>
                <Input type="email" name="email" placeholder="@" value={newContactData.email} onChange={e => setNewContactData({ ...newContactData, email: e.target.value })} className="h-12 rounded-xl bg-slate-50 border-none font-bold text-sm" />
              </div>
            </div>
            <div className="space-y-2">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">태그 (컴마 구분)</label>
              <Input name="tags" placeholder="VIP, 전략, 신규 인연" className="h-12 rounded-xl bg-slate-50 border-none font-bold" />
            </div>
            <div className="pt-4">
              <Button type="submit" className="w-full h-14 rounded-2xl font-bold shadow-lg shadow-primary/20 text-base">
                파트너 정보 저장
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={isMeetingModalOpen} onOpenChange={setIsMeetingModalOpen}>
        <DialogContent className="sm:max-w-2xl rounded-[32px] p-8 max-h-[90vh] overflow-y-auto">
          <DialogHeader className="mb-6">
            <DialogTitle className="text-2xl font-bold tracking-tight italic">비즈니스 로그 기록</DialogTitle>
            <DialogDescription className="font-medium">미팅 중 나눈 대화와 다음 일정을 기록해 두세요.</DialogDescription>
          </DialogHeader>
          <form onSubmit={handleSaveMeeting} className="space-y-6">
            <div className="space-y-2">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">대상 거래처 선택</label>
              <select
                name="contactId" required defaultValue={selectedContactId || ""}
                className="w-full h-12 px-4 rounded-xl bg-slate-50 border-none font-bold text-sm text-slate-700 outline-none focus:ring-2 focus:ring-primary/20 transition-all"
              >
                <option value="" disabled>디렉토리에서 선택</option>
                {contacts.map(c => <option key={c.id} value={c.id}>{c.name} ({c.company})</option>)}
              </select>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">미팅 일자</label>
                <Input type="date" name="date" required defaultValue={new Date().toISOString().slice(0, 10)} className="h-12 rounded-xl bg-slate-50 border-none font-bold" />
              </div>
              <div className="space-y-2">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">장소</label>
                <Input name="location" placeholder="어디서 미팅했나요?" className="h-12 rounded-xl bg-slate-50 border-none font-bold" />
              </div>
            </div>
            <div className="relative">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1 mb-2 block">활동 기록 (음성 지원)</label>
              <Button
                type="button" variant="secondary" size="icon"
                onClick={toggleSTT}
                className={cn(
                  "absolute right-3 top-9 z-10 rounded-full transition-all",
                  isListening ? "bg-red-500 text-white animate-pulse" : "bg-white shadow-sm border border-slate-100"
                )}
              >
                {isListening ? <MicOff /> : <Mic />}
              </Button>
              <textarea
                name="content" required value={meetingContent} onChange={(e) => setMeetingContent(e.target.value)}
                placeholder="나눈 대화의 핵심을 말하거나 입력하세요..."
                className="w-full p-6 bg-slate-50 rounded-[28px] border-none focus:ring-4 focus:ring-primary/5 h-40 md:h-52 resize-none font-medium text-sm leading-relaxed"
              />
            </div>

            <div className="bg-primary p-6 md:p-8 rounded-[36px] shadow-xl shadow-primary/10 relative overflow-hidden group">
              <Sparkles size={60} className="absolute -right-4 -bottom-4 text-white/10 group-hover:scale-110 transition-transform" />
              <label className="text-[10px] font-bold text-white/70 mb-3 block uppercase tracking-widest text-center">팔로업(Follow-up) 일정 알림</label>
              <Input type="date" name="nextSchedule" className="h-14 bg-white border-none rounded-2xl text-center font-black text-primary text-2xl shadow-inner cursor-pointer" />
            </div>

            <div className="pt-2">
              <Button
                type="submit"
                disabled={isAiGenerating || !meetingContent}
                className="w-full h-16 rounded-[24px] font-bold text-lg shadow-xl shadow-slate-200 transition-all active:scale-95 disabled:opacity-50"
              >
                {isAiGenerating ? <><Loader2 className="animate-spin mr-2" /> AI 분석 생성 중...</> : "인텔 로그 동기화"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={isScheduleModalOpen} onOpenChange={setIsScheduleModalOpen}>
        <DialogContent className="sm:max-w-md rounded-[32px] p-8">
          <DialogHeader className="mb-6">
            <DialogTitle className="text-2xl font-bold tracking-tight italic">팔로업 일정 등록</DialogTitle>
            <DialogDescription className="font-medium">다음 미팅이나 연락 일정을 잡아두세요.</DialogDescription>
          </DialogHeader>
          <form onSubmit={handleSaveSchedule} className="space-y-6">
            <div className="space-y-2">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">대상 거래처 선택</label>
              <select
                name="contactId" required defaultValue={selectedContactId || ""}
                className="w-full h-12 px-4 rounded-xl bg-slate-50 border-none font-bold text-sm text-slate-700 outline-none focus:ring-2 focus:ring-primary/20 transition-all"
              >
                <option value="" disabled>디렉토리에서 선택</option>
                {contacts.map(c => <option key={c.id} value={c.id}>{c.name} ({c.company})</option>)}
              </select>
            </div>
            <div className="space-y-2">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">예정 날짜</label>
              <Input type="date" name="date" required className="h-12 rounded-xl bg-slate-50 border-none font-bold" />
            </div>
            <div className="pt-4">
              <Button type="submit" className="w-full h-14 rounded-2xl font-bold shadow-lg shadow-primary/20 text-base">
                일정 확정
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}

// --- Internal Components ---

function StatCard({ label, value, icon, active, onClick, action }: { label: string, value: number, icon: React.ReactNode, active: boolean, onClick: () => void, action?: React.ReactNode }) {
  return (
    <Card
      onClick={onClick}
      className={cn(
        "cursor-pointer rounded-3xl transition-all duration-300 border-slate-100 group",
        active ? "shadow-lg scale-102 ring-2 ring-primary/20 border-primary/20 bg-white" : "shadow-sm hover:shadow-md hover:bg-slate-50/50 bg-white"
      )}
    >
      <CardContent className="p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="space-y-1">
            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest leading-none">{label}</p>
            <h4 className="text-3xl font-bold tracking-tight text-slate-900">{value}</h4>
          </div>
          <div className={cn(
            "p-3 rounded-2xl transition-all shadow-sm shrink-0",
            active ? "bg-primary text-white" : "bg-slate-50 text-slate-300"
          )}>
            {React.cloneElement(icon as React.ReactElement<any>, { size: 24, strokeWidth: 2.5 })}
          </div>
        </div>
        {action && (
          <div className="pt-2">
            {action}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function ContactCard({ contact, onAddLog, onDelete }: { contact: Contact, onAddLog: () => void, onDelete: () => void }) {
  return (
    <Card className="rounded-3xl border-slate-100 shadow-sm hover:shadow-md transition-shadow group overflow-hidden">
      <CardContent className="p-5 space-y-5">
        <div className="flex justify-between items-start">
          <div className="flex items-center gap-3">
            <Avatar className="w-11 h-11 border border-slate-100 shadow-sm">
              <AvatarFallback className="bg-primary/5 text-primary text-sm font-bold">{contact.name?.[0]}</AvatarFallback>
            </Avatar>
            <div className="overflow-hidden">
              <h4 className="font-bold text-slate-900 leading-tight truncate">{contact.name}님</h4>
              <p className="text-[10px] text-slate-400 font-bold uppercase truncate">{contact.company} · {contact.position || "파트너"}</p>
            </div>
          </div>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full text-slate-300 hover:text-slate-600">
                <MoreVertical size={16} />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="rounded-xl border-slate-100">
              <DropdownMenuItem onClick={onDelete} className="text-destructive font-bold text-xs cursor-pointer focus:text-destructive">
                <Trash2 className="w-4 h-4 mr-2" /> 정보 삭제
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>

        <div className="flex flex-wrap gap-1">
          {contact.tags?.map((tag, i) => (
            <Badge key={i} variant="secondary" className="px-2 py-0.5 text-[8px] font-bold bg-slate-50 text-slate-400 border-none tracking-tight">#{tag}</Badge>
          ))}
        </div>

        <div className="flex flex-col gap-2 pt-2 border-t border-slate-50">
          <div className="flex items-center gap-2 text-slate-400">
            <Clock size={12} />
            <p className="text-[10px] font-bold tracking-tight">{contact.phone || "연락처 미등록"}</p>
          </div>
          <div className="flex items-center justify-between pt-1">
            {contact.nextSchedule ? (
              <Badge className="rounded-full px-3 py-1 bg-primary text-white text-[9px] font-bold border-none shadow-sm shadow-primary/10">
                {contact.nextSchedule} 예정
              </Badge>
            ) : (
              <p className="text-[9px] font-bold text-slate-300">로그 내역 없음</p>
            )}
            <Button variant="outline" size="xs" onClick={onAddLog} className="rounded-full text-[10px] font-bold border-slate-100 h-7 px-3">
              <Plus className="w-3 h-3 mr-1" /> 로그 추가
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function MeetingCard({ meeting, onDelete }: { meeting: Meeting, onDelete: () => void }) {
  return (
    <Card className="rounded-[40px] border-slate-100 shadow-sm overflow-hidden mb-8">
      <CardHeader className="p-6 md:p-8 flex flex-row items-center justify-between space-y-0">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-slate-900 text-white flex items-center justify-center shadow-lg">
            <MessageSquare size={20} />
          </div>
          <div>
            <CardTitle className="text-xl font-bold tracking-tight">{meeting.contactName}님과의 미팅</CardTitle>
            <div className="flex items-center gap-2 mt-1">
              <Badge variant="outline" className="text-[9px] font-bold rounded-md bg-slate-50 border-none text-slate-400">{meeting.date}</Badge>
              {meeting.location && <p className="text-[10px] text-slate-300 font-bold uppercase">{meeting.location}</p>}
            </div>
          </div>
        </div>
        <Button variant="ghost" size="icon" onClick={onDelete} className="text-slate-200 hover:text-destructive transition-colors rounded-full">
          <X size={20} />
        </Button>
      </CardHeader>

      <CardContent className="px-6 md:px-8 pb-8 space-y-8">
        {meeting.aiSummary && (
          <div className="bg-primary/5 rounded-[32px] p-6 md:p-8 border border-primary/10 space-y-6">
            <div className="flex items-center gap-2 text-primary">
              <Sparkles size={16} />
              <span className="text-[10px] font-black uppercase tracking-widest">AI 파트너 브리핑</span>
            </div>
            <p className="text-slate-700 font-bold text-lg md:text-xl leading-relaxed italic">
              "{meeting.aiSummary.peer_briefing}"
            </p>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="bg-white p-5 rounded-2xl shadow-sm space-y-2">
                <h5 className="text-[9px] font-bold text-slate-400 uppercase tracking-wider">현장 분위기</h5>
                <p className="text-xs text-slate-600 font-medium leading-relaxed">{meeting.aiSummary.vibe_check}</p>
              </div>
              <div className="bg-white p-5 rounded-2xl shadow-sm space-y-2">
                <h5 className="text-[9px] font-bold text-slate-400 uppercase tracking-wider">실행 전략</h5>
                <ul className="space-y-1.5">
                  {meeting.aiSummary.next_action_tips?.map((tip: string, i: number) => (
                    <li key={i} className="text-[11px] text-primary font-bold flex items-start gap-2 leading-tight">
                      <span className="mt-1.5 w-1 h-1 bg-primary/40 rounded-full shrink-0" /> {tip}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
            <p className="text-primary/60 text-[10px] font-bold italic text-center pt-2">
              {meeting.aiSummary.cheering_message}
            </p>
          </div>
        )}

        <div className="space-y-3">
          <h5 className="text-[10px] font-bold text-slate-300 uppercase tracking-widest ml-1">나눈 대화 기록</h5>
          <div className="bg-slate-50/70 p-6 rounded-3xl border border-slate-100 font-medium text-slate-600 text-sm leading-relaxed italic">
            "{meeting.content}"
          </div>
        </div>

        {meeting.nextSchedule && (
          <div className="flex items-center gap-2 bg-slate-900 px-6 py-4 rounded-full text-white w-fit shadow-xl shadow-slate-900/10">
            <Calendar className="w-4 h-4" />
            <span className="text-xs font-bold font-mono tracking-tight">NEXT STEP: {meeting.nextSchedule}</span>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function CalendarView({ contacts }: { contacts: Contact[] }) {
  const [currentMonth, setCurrentMonth] = useState(new Date());

  const daysInMonth = (date: Date) => new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
  const firstDayOfMonth = (date: Date) => new Date(date.getFullYear(), date.getMonth(), 1).getDay();

  const prevMonth = () => setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1));
  const nextMonth = () => setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1));

  const days = Array.from({ length: daysInMonth(currentMonth) }, (_, i) => i + 1);
  const blanks = Array.from({ length: firstDayOfMonth(currentMonth) }, (_, i) => i);

  const getSchedulesForDay = (day: number) => {
    const dateStr = `${currentMonth.getFullYear()}-${String(currentMonth.getMonth() + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    return contacts.filter(c => c.nextSchedule === dateStr);
  };

  return (
    <Card className="rounded-[32px] border-slate-100 shadow-sm p-4 md:p-6 bg-white overflow-hidden">
      <div className="flex items-center justify-between mb-6 px-2">
        <h4 className="text-lg font-black text-slate-800 tracking-tight">
          {currentMonth.getFullYear()}년 {currentMonth.getMonth() + 1}월
        </h4>
        <div className="flex gap-1">
          <Button variant="ghost" size="icon" onClick={prevMonth} className="rounded-full h-8 w-8"><ChevronLeft size={18} /></Button>
          <Button variant="ghost" size="icon" onClick={nextMonth} className="rounded-full h-8 w-8"><ChevronRight size={18} /></Button>
        </div>
      </div>

      <div className="grid grid-cols-7 gap-1 mb-2">
        {['일', '월', '화', '수', '목', '금', '토'].map((day, i) => (
          <div key={day} className={cn("text-center text-[10px] font-bold text-slate-400 py-2", i === 0 && "text-red-400", i === 6 && "text-blue-400")}>
            {day}
          </div>
        ))}
      </div>

      <div className="grid grid-cols-7 gap-1">
        {blanks.map(i => <div key={`blank-${i}`} className="h-20 sm:h-24 md:h-28" />)}
        {days.map(day => {
          const schedules = getSchedulesForDay(day);
          const isToday = new Date().toDateString() === new Date(currentMonth.getFullYear(), currentMonth.getMonth(), day).toDateString();

          return (
            <div
              key={day}
              className={cn(
                "h-20 sm:h-24 md:h-28 bg-slate-50/50 rounded-2xl p-1.5 flex flex-col gap-1 transition-all border border-transparent",
                isToday && "bg-primary/5 border-primary/20 ring-1 ring-primary/10"
              )}
            >
              <span className={cn(
                "text-[11px] font-black ml-1 mt-0.5",
                isToday ? "text-primary" : "text-slate-500"
              )}>
                {day}
              </span>
              <div className="flex-1 overflow-y-auto space-y-1 scrollbar-hide">
                {schedules.map(c => (
                  <div key={c.id} className="bg-white px-2 py-1 rounded-lg text-[9px] font-bold text-slate-700 shadow-sm border border-slate-100 truncate flex items-center gap-1">
                    <div className="w-1.5 h-1.5 rounded-full bg-primary shrink-0" />
                    <span className="truncate">{c.name}</span>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </Card>
  );
}

// --- Footer & Legal Components ---

function Footer({ onOpenTerms, onOpenPrivacy }: { onOpenTerms: () => void, onOpenPrivacy: () => void }) {
  return (
    <footer className="w-full bg-white border-t border-slate-200 pt-16 pb-32 md:pb-16 mt-20">
      <div className="max-w-screen-xl mx-auto px-6 md:px-8">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-12 mb-12">
          {/* Brand Side */}
          <div className="space-y-4">
            <LogBLogo variant="horizontal" />
            <p className="text-sm text-slate-400 leading-relaxed max-w-sm font-medium">
              Log:B는 당신의 모든 비즈니스 대화와 일정을 자산으로 만드는 스마트 세일즈 인텔리전스 레이어입니다.
            </p>
          </div>

          {/* Info Side */}
          <div className="grid grid-cols-2 gap-8">
            <div className="space-y-4">
              <h4 className="text-[11px] font-black text-slate-900 uppercase tracking-widest">Legal</h4>
              <ul className="space-y-3">
                <li>
                  <button onClick={onOpenTerms} className="text-sm text-slate-500 hover:text-indigo-600 font-bold flex items-center gap-1.5 transition-colors">
                    <FileText size={14} /> 이용약관
                  </button>
                </li>
                <li>
                  <button onClick={onOpenPrivacy} className="text-sm text-slate-500 hover:text-indigo-600 font-bold flex items-center gap-1.5 transition-colors">
                    <ShieldCheck size={14} /> 개인정보처리방침
                  </button>
                </li>
              </ul>
            </div>
            <div className="space-y-4">
              <h4 className="text-[11px] font-black text-slate-900 uppercase tracking-widest">Contact</h4>
              <ul className="space-y-3">
                <li>
                  <a href="mailto:support@log-b.ai" className="text-sm text-slate-500 hover:text-indigo-600 font-bold flex items-center gap-1.5 transition-colors">
                    <Mail size={14} /> 고객센터
                  </a>
                </li>
                <li>
                  <a href="https://log-biz.vercel.app" target="_blank" className="text-sm text-slate-500 hover:text-indigo-600 font-bold flex items-center gap-1.5 transition-colors">
                    <ExternalLink size={14} /> 서비스 홈
                  </a>
                </li>
              </ul>
            </div>
          </div>
        </div>

        {/* Business Info Layer (Common for B2B) */}
        <div className="border-t border-slate-100 pt-8 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div className="space-y-1">
            <p className="text-[11px] text-slate-400 font-bold tracking-tight">
              회사: (주)루시퍼 | 이메일: nextidealab.ai@gmail.com
            </p>
            <p className="text-[11px] text-slate-400 font-bold uppercase tracking-wider">
              &copy; 2026 Next Idea Lab By Lucifer Co., Ltd. All Rights Reserved.
            </p>
          </div>
          <div className="flex items-center gap-4 opacity-30 grayscale hover:grayscale-0 hover:opacity-100 transition-all">
            <div className="text-[10px] font-black border border-slate-400 px-2 py-0.5 rounded">SSL SECURE</div>
            <div className="text-[10px] font-black border border-slate-400 px-2 py-0.5 rounded">FIREBASE CLOUD</div>
          </div>
        </div>
      </div>
    </footer>
  );
}

function LegalModals({
  isTermsOpen, setIsTermsOpen,
  isPrivacyOpen, setIsPrivacyOpen
}: {
  isTermsOpen: boolean, setIsTermsOpen: (v: boolean) => void,
  isPrivacyOpen: boolean, setIsPrivacyOpen: (v: boolean) => void
}) {
  return (
    <>
      <Dialog open={isTermsOpen} onOpenChange={setIsTermsOpen}>
        <DialogContent className="sm:max-w-2xl rounded-[32px] p-8 max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-xl font-black tracking-tight">서비스 이용약관</DialogTitle>
          </DialogHeader>
          <div className="mt-8 text-sm text-slate-600 font-medium leading-relaxed space-y-6">
            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">제1조 (목적)</h3>
              <p>본 약관은 Log:B(이하 "서비스")가 제공하는 제반 서비스의 이용과 관련하여 서비스와 회원 사이의 권리, 의무 및 책임 사항, 기타 필요한 사항을 규정함을 목적으로 합니다.</p>
            </section>

            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">제2조 (용어의 정의)</h3>
              <ol className="list-decimal list-inside space-y-2">
                <li>"서비스"라 함은 회원이 비즈니스 거래처 정보를 관리하고 미팅 내용을 기록/분석할 수 있도록 제공되는 'Log:B' 웹 서비스를 의미합니다.</li>
                <li>"회원"이라 함은 본 약관에 동의하고 서비스를 이용하는 이용자를 말합니다.</li>
              </ol>
            </section>

            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">제3조 (약관의 효력 및 변경)</h3>
              <ol className="list-decimal list-inside space-y-2">
                <li>본 약관은 서비스 내에 게시하거나 기타의 방법으로 회원에게 공지함으로써 효력이 발생합니다.</li>
                <li>서비스는 필요하다고 인정되는 경우 관련 법령을 위배하지 않는 범위 내에서 약관을 변경할 수 있습니다.</li>
              </ol>
            </section>

            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">제4조 (서비스의 내용 및 변경)</h3>
              <ol className="list-decimal list-inside space-y-2">
                <li>서비스는 다음과 같은 기능을 제공합니다.
                  <ul className="list-disc list-inside ml-6 mt-1 opacity-80">
                    <li>거래처 정보 관리 및 일괄 등록(CSV)</li>
                    <li>음성 및 텍스트 기반 미팅 리포트 작성</li>
                    <li>AI 기반 미팅 요약 및 비즈니스 인사이트 도출</li>
                    <li>일정 관리 및 대시보드 제공</li>
                  </ul>
                </li>
                <li>서비스는 기술적 사양의 변경이나 운영상 필요에 따라 서비스의 내용을 변경할 수 있습니다.</li>
              </ol>
            </section>

            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">제5조 (개인정보 보호)</h3>
              <p>서비스는 회원의 개인정보를 보호하기 위해 노력하며, 개인정보의 보호 및 사용에 대해서는 관련 법령 및 "개인정보처리방침"에 따릅니다.</p>
            </section>

            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">제6조 (서비스 이용의 제한 및 중단)</h3>
              <ol className="list-decimal list-inside space-y-2">
                <li>회원이 서비스의 정상적인 운영을 방해하거나 타인의 권리를 침해하는 경우 서비스 이용을 제한할 수 있습니다.</li>
                <li>시스템 점검, 교체 및 고장, 통신두절 등의 사유가 발생한 경우 서비스 제공을 일시적으로 중단할 수 있습니다.</li>
              </ol>
            </section>

            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">제7조 (책임 제한 및 면책)</h3>
              <ol className="list-decimal list-inside space-y-2">
                <li>서비스는 천재지변, 전시, 기타 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 관한 책임이 면제됩니다.</li>
                <li>서비스는 AI 기능을 통해 제공되는 요약 및 분석 결과의 완전성, 정확성, 유용성에 대해 보증하지 않으며, 이를 신뢰하여 발생한 결과에 대해 책임을 지지 않습니다.</li>
                <li>회원이 서비스에 저장한 데이터의 관리 책임은 회원 본인에게 있으며, 회원의 부주의로 인한 데이터 유출이나 삭제에 대해 서비스는 책임을 지지 않습니다.</li>
              </ol>
            </section>

            <footer className="pt-6 border-t border-slate-100 text-[11px] font-bold text-slate-400">
              <p>공고일자: 2024년 5월 22일</p>
              <p>시행일자: 2024년 5월 22일</p>
            </footer>
          </div>
          <div className="mt-8 sticky bottom-0 pt-4 bg-white">
            <Button onClick={() => setIsTermsOpen(false)} className="w-full h-14 rounded-2xl font-black text-base shadow-xl shadow-primary/10">약관 동의 및 확인</Button>
          </div>
        </DialogContent>
      </Dialog>

      <Dialog open={isPrivacyOpen} onOpenChange={setIsPrivacyOpen}>
        <DialogContent className="sm:max-w-2xl rounded-[32px] p-8 max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-xl font-black tracking-tight">개인정보처리방침</DialogTitle>
          </DialogHeader>
          <div className="mt-8 text-sm text-slate-600 font-medium leading-relaxed space-y-6">
            <p className="p-4 bg-slate-50 rounded-2xl border border-slate-100 italic">
              Log:B(이하 "서비스")는 이용자의 개인정보를 소중히 다루며, 「개인정보 보호법」 등 관련 법령을 준수합니다. 본 방침을 통해 회원이 제공하는 개인정보가 어떤 용도와 방식으로 이용되고 있으며, 보호를 위해 어떤 조치가 취해지고 있는지 알려드립니다.
            </p>

            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">1. 수집하는 개인정보 항목 및 수집방법</h3>
              <ul className="list-disc list-inside space-y-2">
                <li><strong>수집 항목:</strong> (필수) 이메일 주소, 이름, 프로필 사진 (Google 로그인 연동 시)</li>
                <li className="ml-6 opacity-80">(선택) 서비스 이용 기록, 접속 로그, 쿠키, 접속 IP 정보</li>
                <li><strong>수집 방법:</strong> 홈페이지(구글 로그인), 서비스 이용 과정에서의 자동 생성</li>
              </ul>
            </section>

            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">2. 개인정보의 수집 및 이용목적</h3>
              <ol className="list-decimal list-inside space-y-2">
                <li>회원 가입 의사 확인 및 본인 식별</li>
                <li>비즈니스 로그 관리, AI 요약 리포트 제공 등 서비스 핵심 기능 제공</li>
                <li>서비스 이용 통계 분석 및 품질 개선</li>
                <li>불량 이용 방지 및 비인가 사용 방지</li>
              </ol>
            </section>

            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">3. 개인정보의 보유 및 이용기간</h3>
              <p>회원의 개인정보는 원칙적으로 회원 탈퇴 시까지 보유하며, 목적 달성 시 지체 없이 파기합니다. 단, 관계 법령에 따라 보존할 필요가 있는 경우 해당 기간 동안 보관합니다.</p>
            </section>

            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">4. 데이터 저장 및 제3자 제공 (Firebase & Google)</h3>
              <p>서비스는 안정적인 데이터 관리와 AI 기능 제공을 위해 다음과 같이 외부 인프라를 활용합니다.</p>
              <ul className="list-disc list-inside space-y-2">
                <li><strong>수탁업체: Google Cloud (Firebase)</strong><br /><span className="ml-6 text-xs text-slate-400">데이터 클라우드 저장, 사용자 인증 관리</span></li>
                <li><strong>수탁업체: Google Gemini API</strong><br /><span className="ml-6 text-xs text-slate-400">미팅 기록의 텍스트 요약 및 비즈니스 조언 생성 (AI 학습 비재사용 설정)</span></li>
              </ul>
            </section>

            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">5. 이용자의 권리와 의무</h3>
              <p>이용자는 언제든지 자신의 개인정보를 조회하거나 수정할 수 있으며, 회원 탈퇴를 통해 개인정보 이용에 대한 동의를 철회할 수 있습니다.</p>
            </section>

            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">6. 개인정보의 파기절차 및 방법</h3>
              <p>회원이 탈퇴하거나 개인정보 보유 기간이 경과된 경우, 전자적 파일 형태의 정보는 기록을 재생할 수 없는 기술적 방법을 사용하여 파기합니다.</p>
            </section>

            <section className="space-y-4">
              <h3 className="text-base font-bold text-slate-900">7. 쿠키(Cookie)의 운용 및 거부</h3>
              <p>서비스는 개인화된 서비스 제공을 위해 쿠키를 사용하며, 회원은 브라우저 설정을 통해 쿠키 저장을 거부할 수 있습니다. 단, 이 경우 서비스 이용에 일부 제한이 있을 수 있습니다.</p>
            </section>

            <footer className="pt-6 border-t border-slate-100 text-[11px] font-bold text-slate-400">
              <p>이메일 문의: support@log-b.ai</p>
              <p>버전번호: 1.0 | 최종 업데이트: 2024년 5월 22일</p>
            </footer>
          </div>
          <div className="mt-8 sticky bottom-0 pt-4 bg-white">
            <Button onClick={() => setIsPrivacyOpen(false)} className="w-full h-14 rounded-2xl font-black text-base shadow-xl shadow-primary/10">확인</Button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}
