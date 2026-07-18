import { useState } from "react";
import { Bell, Building2, ChevronDown, CircleHelp, Database, LayoutDashboard, Menu, PackageSearch, Search, Settings2, Shapes, UserRoundCog, UsersRound, X } from "lucide-react";
import { demoMeta, institution } from "@anyangtai/demo-data";
import { IconButton } from "./components/Ui";
import { CatalogPage } from "./pages/CatalogPage";
import { DashboardPage } from "./pages/DashboardPage";
import { EldersPage } from "./pages/EldersPage";
import { InstitutionPage } from "./pages/InstitutionPage";
import { RelationshipsPage } from "./pages/RelationshipsPage";
import { SitesPage } from "./pages/SitesPage";
import { StaffPage } from "./pages/StaffPage";
import { SystemPage } from "./pages/SystemPage";
import "./App.css";

type PageKey = "dashboard" | "institution" | "sites" | "staff" | "catalog" | "elders" | "relationships" | "system";

const navGroups: Array<{ label: string; items: Array<{ key: PageKey; label: string; icon: typeof LayoutDashboard; hint?: string }> }> = [
  { label: "工作", items: [{ key: "dashboard", label: "工作台", icon: LayoutDashboard }] },
  { label: "基础配置", items: [{ key: "institution", label: "机构资料", icon: Building2 }, { key: "sites", label: "场地与资源", icon: Shapes }, { key: "staff", label: "员工与任职", icon: UserRoundCog }] },
  { label: "服务配置", items: [{ key: "catalog", label: "服务目录与定价", icon: PackageSearch }] },
  { label: "服务对象", items: [{ key: "elders", label: "老人档案", icon: UsersRound, hint: "46" }, { key: "relationships", label: "服务关系", icon: Settings2, hint: "54" }] },
];

const pageLabels: Record<PageKey, string> = { dashboard: "工作台", institution: "机构资料", sites: "场地与资源", staff: "员工与任职", catalog: "服务目录与定价", elders: "老人档案", relationships: "服务关系", system: "本地数据与系统状态" };

function App() {
  const [page, setPage] = useState<PageKey>("dashboard");
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);

  function navigate(next: PageKey) { setPage(next); setSidebarOpen(false); window.scrollTo({ top: 0, behavior: "smooth" }); }
  function renderPage() {
    switch (page) {
      case "dashboard": return <DashboardPage onNavigate={navigate} />;
      case "institution": return <InstitutionPage />;
      case "sites": return <SitesPage />;
      case "staff": return <StaffPage />;
      case "catalog": return <CatalogPage />;
      case "elders": return <EldersPage onOpenRelationships={() => navigate("relationships")} />;
      case "relationships": return <RelationshipsPage />;
      case "system": return <SystemPage />;
    }
  }

  return (
    <div className="app-shell">
      {sidebarOpen && <button className="mobile-backdrop" aria-label="关闭菜单" onClick={() => setSidebarOpen(false)} />}
      <aside className={`sidebar ${sidebarOpen ? "is-open" : ""}`}>
        <div className="brand"><div className="brand-mark"><span>安</span></div><div><strong>安养台</strong><small>机构管理工具</small></div><IconButton label="关闭菜单" className="sidebar-close" onClick={() => setSidebarOpen(false)}><X size={18} /></IconButton></div>
        <button type="button" className="institution-switcher" onClick={() => navigate("institution")}><div className="institution-switcher__mark">云</div><div><strong>{institution.shortName}</strong><span>{demoMeta.label}</span></div><ChevronDown size={15} /></button>
        <nav className="sidebar-nav">{navGroups.map((group) => <div className="nav-group" key={group.label}><span className="nav-group__label">{group.label}</span>{group.items.map((item) => { const Icon = item.icon; return <button type="button" key={item.key} className={page === item.key ? "is-active" : ""} onClick={() => navigate(item.key)}><Icon size={18} /><span>{item.label}</span>{item.hint && <em>{item.hint}</em>}</button>; })}</div>)}</nav>
        <div className="sidebar-footer"><button type="button" className={page === "system" ? "is-active" : ""} onClick={() => navigate("system")}><Database size={18} /><span>本地数据与系统</span></button><div className="local-status"><span /><div><strong>数据保存在本机</strong><small>匿名演示模式</small></div></div></div>
      </aside>

      <div className="app-main">
        <header className="topbar">
          <div className="topbar-left"><IconButton label="打开菜单" className="menu-button" onClick={() => setSidebarOpen(true)}><Menu size={20} /></IconButton><div className="breadcrumb"><span>安养台</span><i>/</i><strong>{pageLabels[page]}</strong></div></div>
          <div className="topbar-actions"><button type="button" className="command-search" onClick={() => setSearchOpen(true)}><Search size={16} /><span>搜索老人、员工、服务…</span><kbd>⌘ K</kbd></button><span className="demo-pill">匿名演示</span><IconButton label="帮助"><CircleHelp size={18} /></IconButton><IconButton label="通知" className="notification-button"><Bell size={18} /><span /></IconButton><button type="button" className="operator"><span>陈</span><div><strong>陈立新</strong><small>当前操作人员</small></div><ChevronDown size={14} /></button></div>
        </header>
        <main className="page-content">{renderPage()}<footer className="app-footer"><span>安养台 V0.1 原型 · 本地优先</span><span>{demoMeta.notice}</span></footer></main>
      </div>

      {searchOpen && <div className="command-root"><button className="command-backdrop" aria-label="关闭搜索" onClick={() => setSearchOpen(false)} /><div className="command-dialog" role="dialog" aria-modal="true"><div className="command-input"><Search size={19} /><input autoFocus placeholder="搜索老人、员工、服务项目或页面…" /><kbd>ESC</kbd></div><div className="command-results"><span>快速前往</span>{navGroups.flatMap((group) => group.items).map((item) => { const Icon = item.icon; return <button key={item.key} type="button" onClick={() => { navigate(item.key); setSearchOpen(false); }}><Icon size={17} /><span>{item.label}</span><small>{item.key === "elders" ? "46 位老人" : item.key === "relationships" ? "54 条有效关系" : "打开页面"}</small></button>; })}</div></div></div>}
    </div>
  );
}

export default App;
