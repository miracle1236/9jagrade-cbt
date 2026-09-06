"use client";
import Image from "next/image";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import { useEffect,useState } from "react";
export function Nav(){
 const [email,setEmail]=useState<string|null>(null);
 useEffect(()=>{supabase.auth.getUser().then(({data})=>setEmail(data.user?.email??null));
  const {data}=supabase.auth.onAuthStateChange((_e,s)=>setEmail(s?.user?.email??null)); return()=>data.subscription.unsubscribe()},[]);
 return <nav className="nav"><div className="container" style={{display:"flex",alignItems:"center",justifyContent:"space-between"}}>
  <Link href="/"><picture><source media="(prefers-color-scheme: dark)" srcSet="/logo-white.png"/><Image src="/logo-dark.png" alt="9jaGrade" width={360} height={100} className="logo"/></picture></Link>
  <div className="navlinks">{email?<><Link href="/dashboard">Dashboard</Link><Link href="/admin">Admin</Link><button className="btn btn-secondary" onClick={async()=>{await supabase.auth.signOut();location.href="/"}}>Logout</button></>:<><Link href="/login">Login</Link><Link href="/signup" className="btn btn-primary">Create account</Link></>}</div>
 </div></nav>
}