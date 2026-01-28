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
  CalendarCheck,
  History,
  Sparkles
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  signInAnonymously,
  onAuthStateChanged,
  signOut
} from 'firebase/auth';
import {
  collection,
  addDoc,
  onSnapshot,
  deleteDoc,
  doc,
  updateDoc
} from 'firebase/firestore';
import { auth, db } from '@/lib/firebase';
import { cn } from '@/lib/utils';

// --- Branding Component: Option B Symbol ---
const LogBLogo = ({ className = "w-10 h-10" }) => (
  <svg viewBox="0 0 100 100" className={className} fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect width="100" height="100" rx="28" fill="url(#logb_premium_grad)" />
    <g transform="translate(14, 14) scale(0.72)">
      <path
        d="M32 28V72M32 28H54C62.8366 28 70 34.268 70 42C70 49.732 62.8366 56 54 56H32M32 56H58C67.9411 56 76 63.1634 76 72C76 80.8366 67.9411 88 58 88H32"
        stroke="white"
        strokeWidth="11"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="37.5" cy="37.5" r="4.5" fill="white" />
    </g>
    <defs>
      <linearGradient id="logb_premium_grad" x1="0" y1="0" x2="100" y2="100" gradientUnits="userSpaceOnUse">
        <stop stopColor="#4F46E5" />
        <stop offset="1" stopColor="#2563EB" />
      </linearGradient>
    </defs>
  </svg>
);

interface Contact {
  id: string;
  name: string;
  company: string;
  position?: string;
  phone?: string;
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

export default function App() {
  const [user, setUser] = useState<any>(null);
  const [activeTab, setActiveTab] = useState('contacts');
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [meetings, setMeetings] = useState<Meeting[]>([]);
  const [searchQuery, setSearchQuery] = useState('');

  const [isContactModalOpen, setIsContactModalOpen] = useState(false);
  const [isMeetingModalOpen, setIsMeetingModalOpen] = useState(false);
  const [selectedContactId, setSelectedContactId] = useState<string | null>(null);

  const [isListening, setIsListening] = useState(false);
  const [meetingContent, setMeetingContent] = useState("");
  const [isAiGenerating, setIsAiGenerating] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const appId = "log-b-mvp";
  const geminiApiKey = process.env.NEXT_PUBLIC_GEMINI_API_KEY;

  // 1. Authentication
  useEffect(() => {
    signInAnonymously(auth).catch(err => console.error("Auth Error:", err));
    return onAuthStateChanged(auth, setUser);
  }, []);

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

  // --- AI Peer Summary Engine ---
  const generateAiPeerSummary = async (content: string, contactName: string) => {
    const systemPrompt = `너는 유능하고 친절한 영업 사수 '로그비'야. 사용자와 함께 발로 뛰는 동료로서 미팅 내용을 정리해줘.
    [응답 원칙]
    1. 톤앤매너: 친근한 구어체 사용 (~했네요, ~인 것 같아요, ~해보세요).
    2. 공감과 응원: 미팅의 고생을 알아주고 응원 메시지 포함.
    3. 핵심 요약: 바쁜 동료를 위해 중요한 내용은 맨 앞에.
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

  // --- Handlers ---
  const handleSaveContact = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!user) return;
    const fd = new FormData(e.currentTarget);
    const data = {
      name: fd.get('name'), company: fd.get('company'), position: fd.get('position'),
      phone: fd.get('phone'), tags: fd.get('tags')?.toString().split(',').map(t => t.trim()).filter(t => t) || [],
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

  const toggleSTT = () => {
    const SpeechRecognition = (window as any).webkitSpeechRecognition || (window as any).SpeechRecognition;
    if (!SpeechRecognition) {
      alert("이 브라우저는 음성 인식을 지원하지 않습니다.");
      return;
    }
    if (isListening) { setIsListening(false); return; }
    const recognition = new SpeechRecognition();
    recognition.lang = 'ko-KR';
    recognition.onstart = () => setIsListening(true);
    recognition.onend = () => setIsListening(false);
    recognition.onresult = (e: any) => setMeetingContent(p => p + " " + e.results[0][0].transcript);
    recognition.start();
  };

  const filteredContacts = contacts.filter(c =>
    c.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.company?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (c.tags && c.tags.some((tag: string) => tag.toLowerCase().includes(searchQuery.toLowerCase())))
  );

  return (
    <div className="flex flex-col min-h-screen bg-[#F8F9FA] font-pretendard text-slate-800 antialiased overflow-x-hidden pb-24 md:pb-0">

      {/* Header Area */}
      <header className="sticky top-0 z-40 w-full bg-white/80 backdrop-blur-xl border-b border-slate-200">
        <div className="max-w-screen-xl mx-auto px-4 md:px-8 h-16 md:h-20 flex items-center justify-between">
          <div className="flex items-center gap-3 cursor-pointer" onClick={() => setActiveTab('contacts')}>
            <LogBLogo className="w-9 h-9 md:w-11 md:h-11 shadow-lg shadow-indigo-500/10 active:scale-95 transition-transform" />
            <div className="flex flex-col">
              <h1 className="text-xl md:text-2xl font-black leading-none tracking-tighter text-slate-900">
                Log<span className="text-primary">:</span>B
              </h1>
              <p className="hidden md:block text-[9px] font-black text-slate-400 uppercase tracking-[0.25em] mt-1.5 italic">Log Business</p>
            </div>
          </div>

          <nav className="hidden md:flex items-center gap-1 bg-slate-100/50 p-1 rounded-2xl">
            {[
              { id: 'contacts', icon: Users, label: '인맥 관리' },
              { id: 'schedule', icon: CalendarCheck, label: '통합 일정' },
              { id: 'meetings', icon: MessageSquare, label: '리포트' },
              { id: 'settings', icon: Settings, label: '설정' }
            ].map(item => (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={cn(
                  "px-5 py-2 rounded-xl text-sm font-bold transition-all flex items-center gap-2",
                  activeTab === item.id ? 'bg-white text-primary shadow-sm scale-105' : 'text-slate-400 hover:text-slate-900'
                )}
              >
                <item.icon size={16} strokeWidth={2.5} /> {item.label}
              </button>
            ))}
          </nav>

          <button
            onClick={() => { setMeetingContent(""); setIsContactModalOpen(true); }}
            className="bg-primary text-white p-2.5 md:px-6 md:py-3 rounded-xl md:rounded-2xl font-black text-sm shadow-lg shadow-primary/20 hover:bg-slate-900 transition-all active:scale-95 flex items-center gap-2"
          >
            <Plus size={20} strokeWidth={3} />
            <span className="hidden md:inline uppercase tracking-widest leading-none">New Contact</span>
          </button>
        </div>
      </header>

      {/* Main Container */}
      <main className="flex-1 w-full max-w-screen-xl mx-auto px-4 md:px-8 py-6 md:py-10">

        {/* Quick Dashboard */}
        <section className="grid grid-cols-1 sm:grid-cols-3 gap-4 md:gap-6 mb-8 md:mb-12">
          <StatCard icon={<Users className="text-primary" />} label="Active Partners" value={contacts.length} trend="+2 new" />
          <StatCard icon={<CalendarCheck className="text-orange-500" />} label="Upcoming Deals" value={contacts.filter(c => c.nextSchedule).length} trend="D-Day tracking" />
          <StatCard icon={<MessageSquare className="text-emerald-500" />} label="Intel Logs" value={meetings.length} trend="Total logs" />
        </section>

        <div className="flex flex-col lg:flex-row gap-8 md:gap-10">

          {/* Left Panel - Hidden on small mobile in main flow, but accessible via search */}
          <aside className="lg:w-80 shrink-0 space-y-6 md:space-y-8">
            <div className="bg-white p-6 md:p-8 rounded-[32px] md:rounded-[48px] shadow-sm border border-slate-200">
              <h3 className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-4 md:mb-6">Search Partner</h3>
              <div className="relative group mb-4 md:mb-6">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-primary transition-colors" size={18} />
                <input
                  value={searchQuery}
                  onChange={e => setSearchQuery(e.target.value)}
                  placeholder="Find leads or tags..."
                  className="w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-[20px] text-sm font-bold focus:outline-none focus:ring-4 focus:ring-primary/5 transition-all"
                />
              </div>
              <div className="flex flex-wrap gap-2">
                {['#중요', '#VIP', '#Potential', '#신규'].map(tag => (
                  <button key={tag} onClick={() => setSearchQuery(tag.replace('#', ''))} className="px-3 py-1.5 bg-slate-50 text-slate-500 rounded-lg text-[10px] font-black hover:bg-primary hover:text-white transition-all uppercase tracking-widest">
                    {tag}
                  </button>
                ))}
              </div>
            </div>

            <div className="hidden md:block bg-white p-8 rounded-[48px] shadow-sm border border-slate-200">
              <h3 className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-6">Data Mobility</h3>
              <div className="grid grid-cols-2 gap-4">
                <button onClick={() => fileInputRef.current?.click()} className="flex flex-col items-center justify-center p-6 bg-slate-50 rounded-[32px] hover:bg-primary/5 hover:text-primary transition-all text-slate-400 group">
                  <Upload size={24} className="mb-3" />
                  <span className="text-[10px] font-black uppercase tracking-wider">Import</span>
                </button>
                <button onClick={() => downloadCSV(contacts, 'LogB_Data')} className="flex flex-col items-center justify-center p-6 bg-slate-50 rounded-[32px] hover:bg-emerald-50 hover:text-emerald-600 transition-all text-slate-400 group">
                  <Download size={24} className="mb-3" />
                  <span className="text-[10px] font-black uppercase tracking-wider">Export</span>
                </button>
              </div>
            </div>
          </aside>

          {/* Right Panel */}
          <div className="flex-1">
            {activeTab === 'contacts' && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6 animate-in slide-in-from-bottom-2 duration-500">
                {filteredContacts.length === 0 ? (
                  <div className="col-span-full py-20 text-center bg-white rounded-[40px] border border-dashed border-slate-200">
                    <p className="text-slate-400 text-sm font-bold">등록된 거래처가 없습니다.</p>
                    <button onClick={() => setIsContactModalOpen(true)} className="mt-4 text-primary font-bold text-sm">새 거래처 등록하기</button>
                  </div>
                ) : (
                  filteredContacts.map(c => (
                    <ContactCard
                      key={c.id}
                      contact={c}
                      onAddLog={() => { setSelectedContactId(c.id); setIsMeetingModalOpen(true); }}
                      onDelete={() => deleteDoc(doc(db, 'artifacts', appId, 'users', user.uid, 'contacts', c.id))}
                    />
                  ))
                )}
              </div>
            )}

            {activeTab === 'schedule' && (
              <div className="space-y-8 md:space-y-12 animate-in fade-in duration-500">
                <div>
                  <h3 className="flex items-center gap-3 text-lg md:text-xl font-black text-slate-900 mb-6 md:mb-8 px-2 tracking-tighter">
                    <div className="w-9 h-9 md:w-10 md:h-10 bg-primary rounded-[14px] md:rounded-[18px] flex items-center justify-center text-white shadow-lg shadow-primary/20"><CalendarCheck size={18} /></div>
                    Strategic Upcoming
                  </h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6">
                    {contacts.filter(c => c.nextSchedule).length === 0 ? (
                      <p className="text-slate-400 text-sm font-bold italic col-span-full py-16 bg-white rounded-[40px] border border-dashed border-slate-200 text-center">No upcoming plans found.</p>
                    ) : (
                      contacts.filter(c => c.nextSchedule)
                        .sort((a, b) => new Date(a.nextSchedule!).getTime() - new Date(b.nextSchedule!).getTime())
                        .map(c => (
                          <div key={c.id} className="bg-white p-6 md:p-8 rounded-[32px] md:rounded-[56px] border-l-[8px] md:border-l-[12px] border-primary shadow-sm flex items-center gap-4 md:gap-6 hover:shadow-xl transition-all">
                            <div className="w-14 h-14 md:w-16 md:h-16 bg-primary/5 rounded-[20px] md:rounded-[24px] flex flex-col items-center justify-center text-primary shrink-0 border border-primary/10">
                              <span className="text-[8px] md:text-[10px] font-black uppercase tracking-tighter">D-Day</span>
                              <span className="text-xl md:text-2xl font-black">{c.nextSchedule?.split('-')[2]}</span>
                            </div>
                            <div className="flex-1">
                              <h4 className="font-black text-slate-900 text-base md:text-lg leading-none mb-1">{c.name}님</h4>
                              <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest">{c.company} · {c.nextSchedule}</p>
                            </div>
                            <button onClick={() => { setSelectedContactId(c.id); setIsMeetingModalOpen(true); }} className="w-10 h-10 md:w-12 md:h-12 bg-slate-900 text-accent rounded-full flex items-center justify-center shadow-xl active:scale-90 transition-all">
                              <Plus size={20} strokeWidth={3} />
                            </button>
                          </div>
                        ))
                    )}
                  </div>
                </div>

                <div>
                  <h3 className="flex items-center gap-3 text-lg md:text-xl font-black text-slate-900 mb-6 md:mb-8 px-2 tracking-tighter">
                    <div className="w-9 h-9 md:w-10 md:h-10 bg-slate-900 rounded-[14px] md:rounded-[18px] flex items-center justify-center text-white shadow-lg"><History size={18} /></div>
                    Past Timeline
                  </h3>
                  <div className="space-y-3">
                    {meetings.length === 0 ? (
                      <p className="text-center py-10 text-slate-400 text-sm font-bold">기록된 미팅이 없습니다.</p>
                    ) : (
                      meetings.slice(0, 10).map(m => (
                        <div key={m.id} className="bg-white p-5 rounded-[24px] shadow-sm border border-slate-100 flex items-center gap-4 hover:shadow-md transition-all group">
                          <div className="w-10 h-10 bg-slate-50 rounded-[14px] flex items-center justify-center text-slate-400 group-hover:bg-primary group-hover:text-white transition-all shrink-0">
                            <MessageSquare size={18} />
                          </div>
                          <div className="flex-1 overflow-hidden">
                            <div className="flex items-center gap-2 mb-0.5">
                              <h4 className="font-black text-slate-800 tracking-tight text-sm">{m.contactName}</h4>
                              <span className="text-[8px] text-primary font-black uppercase tracking-widest bg-primary/5 px-2 py-0.5 rounded-full">{m.date}</span>
                            </div>
                            <p className="text-[11px] text-slate-400 font-medium truncate italic">"{m.content}"</p>
                          </div>
                          <ChevronRight size={18} className="text-slate-200 group-hover:text-primary transition-colors" />
                        </div>
                      ))
                    )}
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'meetings' && (
              <div className="space-y-8 md:space-y-10 animate-in fade-in duration-500">
                {meetings.length === 0 ? (
                  <div className="py-20 text-center bg-white rounded-[40px] border border-dashed border-slate-200">
                    <p className="text-slate-400 text-sm font-bold">생성된 AI 리포트가 없습니다.</p>
                  </div>
                ) : (
                  meetings.map((m) => (
                    <MeetingCard key={m.id} meeting={m} onDelete={() => deleteDoc(doc(db, 'artifacts', appId, 'users', user.uid, 'meetings', m.id))} />
                  ))
                )}
              </div>
            )}

            {activeTab === 'settings' && (
              <motion.div
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                className="bg-white p-10 md:p-16 rounded-[40px] md:rounded-[64px] border border-slate-200 shadow-xl flex flex-col items-center text-center max-w-2xl mx-auto"
              >
                <LogBLogo className="w-20 h-20 md:w-28 md:h-28 mb-8 md:mb-10 shadow-2xl shadow-primary/10" />
                <h2 className="text-3xl md:text-4xl font-black text-slate-900 mb-2 tracking-tighter italic">Log:B Pro</h2>
                <p className="text-slate-400 text-[9px] md:text-[10px] font-black mb-10 md:mb-12 tracking-[0.4em] uppercase">Intelligence Infrastructure</p>
                <div className="w-full space-y-4 mb-10 md:mb-12 text-left">
                  <div className="p-5 md:p-6 bg-slate-50 rounded-[24px] md:rounded-[32px] flex justify-between items-center">
                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">User ID</span>
                    <span className="text-[10px] md:text-xs font-mono font-bold text-slate-900 truncate max-w-[150px] md:max-w-[200px]">{user?.uid}</span>
                  </div>
                  <div className="p-5 md:p-6 bg-slate-50 rounded-[24px] md:rounded-[32px] flex justify-between items-center">
                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Protocol</span>
                    <span className="text-[10px] md:text-xs font-black text-primary uppercase">Cloud Sync Secure</span>
                  </div>
                </div>
                <button onClick={() => signOut(auth)} className="w-full py-5 md:py-6 bg-red-50 text-red-500 font-black rounded-[24px] md:rounded-[32px] hover:bg-red-500 hover:text-white transition-all text-[10px] md:text-xs uppercase tracking-[0.2em] shadow-lg shadow-red-50/50">Terminate Session</button>
              </motion.div>
            )}
          </div>
        </div>
      </main>

      {/* Floating Bottom Navigation (Mobile View) */}
      <nav className="md:hidden fixed bottom-6 left-6 right-6 bg-slate-900/95 backdrop-blur-2xl border border-white/10 rounded-[32px] shadow-2xl flex justify-around p-2 z-50">
        {[
          { id: 'contacts', icon: Users, label: '인맥' },
          { id: 'schedule', icon: CalendarCheck, label: '일정' },
          { id: 'meetings', icon: MessageSquare, label: '리포트' },
          { id: 'settings', icon: Settings, label: '설정' }
        ].map(item => (activeTab === item.id ? (
          <motion.button
            layoutId="activeTabMobile"
            key={item.id}
            className="flex-1 py-3 rounded-[24px] bg-white text-slate-900 flex flex-col items-center gap-1 shadow-lg"
          >
            <item.icon size={20} strokeWidth={3} />
            <span className="text-[8px] font-black uppercase tracking-tighter">{item.label}</span>
          </motion.button>
        ) : (
          <button
            key={item.id}
            onClick={() => setActiveTab(item.id)}
            className="flex-1 py-3 flex flex-col items-center gap-1 text-slate-500"
          >
            <item.icon size={20} strokeWidth={2} />
            <span className="text-[8px] font-black uppercase tracking-tighter">{item.label}</span>
          </button>
        )))}
      </nav>

      {/* Modals */}
      <AnimatePresence>
        {(isContactModalOpen || isMeetingModalOpen) && (
          <div className="fixed inset-0 bg-slate-900/60 z-50 flex items-end sm:items-center justify-center backdrop-blur-md p-0 sm:p-4">
            <motion.div
              initial={{ y: "100%" }}
              animate={{ y: 0 }}
              exit={{ y: "100%" }}
              transition={{ type: "spring", damping: 25, stiffness: 200 }}
              className="bg-white w-full max-w-2xl rounded-t-[40px] sm:rounded-[48px] p-8 md:p-12 shadow-2xl flex flex-col max-h-[95vh]"
            >
              <div className="w-12 h-1.5 bg-slate-100 rounded-full mx-auto mb-8 shrink-0"></div>
              <div className="flex justify-between items-center mb-8 shrink-0">
                <h3 className="text-3xl font-black text-slate-900 tracking-tighter italic">
                  {isContactModalOpen ? 'New Identity' : 'Log Meeting'}
                </h3>
                <button
                  onClick={() => { setIsContactModalOpen(false); setIsMeetingModalOpen(false); }}
                  className="w-10 h-10 rounded-xl bg-slate-50 flex items-center justify-center text-slate-400 hover:text-red-500 transition-all"
                >
                  <X size={24} />
                </button>
              </div>

              <div className="overflow-y-auto pr-2 scrollbar-hide pb-6">
                {isContactModalOpen ? (
                  <form onSubmit={handleSaveContact} className="space-y-5">
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-1.5">
                        <label className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] ml-4">Full Name</label>
                        <input required name="name" className="w-full p-4 bg-slate-50 rounded-[20px] border-none focus:ring-4 focus:ring-primary/10 font-bold text-sm" />
                      </div>
                      <div className="space-y-1.5">
                        <label className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] ml-4">Company</label>
                        <input required name="company" className="w-full p-4 bg-slate-50 rounded-[20px] border-none focus:ring-4 focus:ring-primary/10 font-bold text-sm" />
                      </div>
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] ml-4">Position</label>
                      <input name="position" className="w-full p-4 bg-slate-50 rounded-[20px] border-none focus:ring-4 focus:ring-primary/10 font-bold text-sm" />
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] ml-4">Contact</label>
                      <input name="phone" className="w-full p-4 bg-slate-50 rounded-[20px] border-none focus:ring-4 focus:ring-primary/10 font-bold text-sm" />
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] ml-4">Tags (Comma separated)</label>
                      <input name="tags" placeholder="VIP, New, Important..." className="w-full p-4 bg-slate-50 rounded-[20px] border-none focus:ring-4 focus:ring-primary/10 font-bold text-sm" />
                    </div>
                    <button type="submit" className="w-full py-5 bg-primary text-white rounded-[24px] font-black text-lg shadow-xl shadow-primary/20 mt-4 active:scale-95 transition-all uppercase tracking-widest">Save Identity</button>
                  </form>
                ) : (
                  <form onSubmit={handleSaveMeeting} className="space-y-5">
                    <div className="space-y-1.5">
                      <label className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] ml-4">Select Target</label>
                      <select name="contactId" required defaultValue={selectedContactId || ""} className="w-full p-4 bg-slate-50 rounded-[20px] border-none focus:ring-4 focus:ring-primary/10 font-black text-slate-700 text-sm">
                        <option value="" disabled>Select from Directory</option>
                        {contacts.map(c => <option key={c.id} value={c.id}>{c.name} ({c.company})</option>)}
                      </select>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-1.5">
                        <label className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] ml-4">Meeting Date</label>
                        <input type="date" name="date" required defaultValue={new Date().toISOString().slice(0, 10)} className="w-full p-4 bg-slate-50 rounded-[20px] border-none font-black text-sm" />
                      </div>
                      <div className="space-y-1.5">
                        <label className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] ml-4">Location</label>
                        <input name="location" placeholder="Coffee shop, etc." className="w-full p-4 bg-slate-50 rounded-[20px] border-none font-bold text-sm" />
                      </div>
                    </div>
                    <div className="relative mt-2">
                      <button type="button" onClick={toggleSTT} className={`absolute right-4 top-4 z-10 p-3 rounded-xl shadow-lg transition-all ${isListening ? 'bg-red-500 text-white animate-pulse' : 'bg-white text-primary border border-slate-100 hover:scale-110'}`}>
                        {isListening ? <MicOff size={24} /> : <Mic size={24} />}
                      </button>
                      <textarea
                        name="content" required value={meetingContent} onChange={(e) => setMeetingContent(e.target.value)}
                        placeholder="Talk about the meeting or type notes..."
                        className="w-full p-6 bg-slate-50 rounded-[32px] border-none focus:ring-4 focus:ring-primary/10 h-48 md:h-60 resize-none font-medium leading-relaxed shadow-inner text-sm"
                      />
                    </div>
                    <div className="bg-primary p-6 md:p-8 rounded-[36px] shadow-xl shadow-primary/10 relative overflow-hidden">
                      <Sparkles size={40} className="absolute -right-2 -bottom-2 text-white/10" />
                      <label className="text-[9px] font-black text-white/70 mb-3 block uppercase tracking-[0.3em] text-center">Next Follow-up Date</label>
                      <input type="date" name="nextSchedule" className="w-full p-3 bg-white border-none rounded-[16px] shadow-inner text-center font-black text-primary text-xl" />
                    </div>
                    <button
                      type="submit"
                      disabled={isAiGenerating || !meetingContent}
                      className="w-full py-5 bg-slate-900 text-white rounded-[24px] font-black text-lg shadow-xl shadow-slate-200 mt-4 active:scale-95 transition-all uppercase tracking-widest flex items-center justify-center gap-3 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {isAiGenerating ? <><Loader2 className="animate-spin" size={20} /> AI Peer Summarizing...</> : "Sync Intel Log"}
                    </button>
                  </form>
                )}
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}

// --- Component Fragments ---

const StatCard = ({ icon, label, value, trend }: { icon: React.ReactNode, label: string, value: number, trend: string }) => (
  <div className="bg-white p-6 md:p-8 rounded-[32px] md:rounded-[48px] shadow-sm border border-slate-100 flex flex-col justify-between hover:shadow-lg transition-all group">
    <div className="flex justify-between items-start mb-6 md:mb-8">
      <div className="p-3 bg-slate-50 rounded-[14px] md:rounded-[18px] group-hover:bg-slate-900 group-hover:text-white transition-all shadow-sm">{icon}</div>
      <span className="text-[8px] md:text-[9px] font-black text-slate-300 uppercase tracking-widest bg-slate-50 px-2.5 py-1 rounded-full">{trend}</span>
    </div>
    <div>
      <h4 className="text-3xl md:text-4xl font-black text-slate-900 leading-none mb-1 tracking-tighter">{value}</h4>
      <p className="text-[9px] md:text-[10px] text-slate-400 font-black uppercase tracking-[0.2em]">{label}</p>
    </div>
  </div>
);

const ContactCard = ({ contact, onAddLog, onDelete }: { contact: any, onAddLog: () => void, onDelete: () => void }) => (
  <div className="bg-white p-5 md:p-8 rounded-[32px] md:rounded-[48px] shadow-sm border border-slate-100 hover:shadow-xl transition-all group relative overflow-hidden">
    <div className="flex justify-between items-start mb-6 md:mb-8">
      <div className="flex items-center gap-3 md:gap-4">
        <div className="w-12 h-12 md:w-14 md:h-14 rounded-[18px] md:rounded-[22px] bg-slate-50 text-slate-900 flex items-center justify-center font-black text-xl border border-slate-100 shadow-inner">
          {contact.name?.[0]}
        </div>
        <div>
          <div className="flex items-center gap-2 mb-0.5">
            <h4 className="font-black text-slate-900 text-base md:text-lg leading-none tracking-tight">{contact.name}님</h4>
            <span className="text-[8px] bg-primary/5 text-primary px-2 py-0.5 rounded-full font-black uppercase tracking-widest">{contact.position || "Partner"}</span>
          </div>
          <p className="text-[11px] text-slate-400 font-bold uppercase tracking-wider">{contact.company}</p>
        </div>
      </div>
      <button onClick={onDelete} className="text-slate-200 hover:text-red-500 transition-colors p-1"><X size={20} /></button>
    </div>
    <div className="flex flex-wrap gap-1.5 mb-6 md:mb-8">
      {contact.tags?.map((tag: string, idx: number) => (
        <span key={idx} className="text-[9px] bg-slate-50 text-slate-500 px-3 py-1 rounded-lg font-black uppercase tracking-widest border border-slate-100">#{tag}</span>
      ))}
    </div>
    <div className="pt-4 md:pt-6 border-t border-slate-50 flex justify-between items-center">
      <div className="flex items-center gap-1.5 text-slate-300">
        <Clock size={12} />
        <p className="text-[9px] font-black uppercase tracking-wider">{contact.phone || "No Number"}</p>
      </div>
      {contact.nextSchedule ? (
        <div className="flex items-center gap-1.5 text-white font-black text-[9px] bg-primary px-4 py-2 rounded-full shadow-lg shadow-primary/10 uppercase tracking-widest">
          {contact.nextSchedule}
        </div>
      ) : (
        <button onClick={onAddLog} className="text-[9px] font-black text-slate-400 hover:text-primary flex items-center gap-1.5 uppercase tracking-widest border border-slate-100 px-3 py-2 rounded-full hover:bg-primary/5 transition-all">
          <Plus size={12} /> Add Log
        </button>
      )}
    </div>
  </div>
);

const MeetingCard = ({ meeting, onDelete }: { meeting: any, onDelete: () => void }) => (
  <div className="relative pl-8 md:pl-12 group">
    <div className="absolute left-0 top-6 md:top-8 w-8 h-8 md:w-10 md:h-10 rounded-[14px] md:rounded-[20px] bg-slate-900 text-accent flex items-center justify-center z-10 shadow-xl group-hover:scale-110 transition-transform">
      <MessageSquare size={16} />
    </div>
    <div className="bg-white p-6 md:p-10 rounded-[32px] md:rounded-[56px] shadow-sm border border-slate-100 mb-6 md:mb-8 hover:shadow-xl transition-all border-l-[8px] md:border-l-[12px] border-l-slate-900 group-hover:border-l-primary/80">
      <div className="flex justify-between items-start mb-6 md:mb-8">
        <span className="text-[9px] font-black text-slate-300 uppercase tracking-widest">{meeting.date}</span>
        <button onClick={onDelete} className="text-slate-200 hover:text-red-400 transition-colors p-1"><X size={18} /></button>
      </div>
      <h4 className="font-black text-slate-900 text-xl md:text-2xl mb-6 md:mb-8 flex items-center gap-2">
        <div className="w-1.5 h-6 bg-primary rounded-full"></div>
        @{meeting.contactName}
      </h4>

      {/* AI Peer Summary Section */}
      {meeting.aiSummary && (
        <div className="mb-6 md:mb-8 bg-primary/5 rounded-[24px] md:rounded-[36px] p-6 md:p-8 border border-primary/10">
          <div className="flex items-center gap-2 mb-3 md:mb-4 text-primary">
            <Sparkles size={16} />
            <span className="text-[10px] font-black uppercase tracking-widest">AI Peer Briefing</span>
          </div>
          <p className="text-slate-700 font-bold text-base md:text-lg leading-relaxed mb-6 italic">
            "{meeting.aiSummary.peer_briefing}"
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6 mb-6">
            <div className="bg-white p-4 md:p-5 rounded-[20px] md:rounded-[24px] shadow-sm">
              <h5 className="text-[9px] font-black text-slate-400 uppercase mb-2">Vibe Check</h5>
              <p className="text-xs text-slate-600 font-medium leading-relaxed">{meeting.aiSummary.vibe_check}</p>
            </div>
            <div className="bg-white p-4 md:p-5 rounded-[20px] md:rounded-[24px] shadow-sm">
              <h5 className="text-[9px] font-black text-slate-400 uppercase mb-2">Action Tips</h5>
              <ul className="space-y-1.5">
                {meeting.aiSummary.next_action_tips?.map((tip: string, i: number) => (
                  <li key={i} className="text-[11px] text-primary font-bold flex items-start gap-2 leading-relaxed">
                    <span className="mt-1.5 w-1 h-1 bg-primary/40 rounded-full shrink-0"></span> {tip}
                  </li>
                ))}
              </ul>
            </div>
          </div>
          <p className="text-primary/60 text-[10px] font-black italic text-center">
            {meeting.aiSummary.cheering_message}
          </p>
        </div>
      )}

      <div className="space-y-3">
        <h5 className="text-[9px] font-black text-slate-400 uppercase tracking-widest ml-2">Raw Log</h5>
        <p className="text-sm text-slate-500 leading-relaxed bg-slate-50/50 p-5 md:p-6 rounded-[24px] font-medium border border-slate-100/50 italic shrink-0">
          "{meeting.content}"
        </p>
      </div>

      {meeting.nextSchedule && (
        <div className="mt-8 flex items-center gap-2 text-[10px] font-black text-white bg-primary px-6 py-3 rounded-[20px] inline-flex shadow-lg shadow-primary/10 uppercase tracking-widest hover:scale-105 transition-transform">
          <Calendar size={14} /> Next: {meeting.nextSchedule}
        </div>
      )}
    </div>
  </div>
);

const downloadCSV = (data: any[], filename: string) => {
  if (!data || data.length === 0) return;
  const headers = Object.keys(data[0]).join(",");
  const rows = data.map(obj =>
    Object.values(obj).map(val => `"${String(val).replace(/"/g, '""')}"`).join(",")
  );
  const csvContent = "data:text/csv;charset=utf-8,\uFEFF" + [headers, ...rows].join("\n");
  const link = document.createElement("a");
  link.setAttribute("href", encodeURI(csvContent));
  link.setAttribute("download", `${filename}_${new Date().toISOString().slice(0, 10)}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};
