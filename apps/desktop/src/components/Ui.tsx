import type { ReactNode } from "react";
import { Search, X } from "lucide-react";

export type Tone = "green" | "blue" | "amber" | "red" | "gray" | "violet";

export function Button({
  children,
  variant = "primary",
  size = "md",
  className = "",
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary" | "ghost" | "danger";
  size?: "sm" | "md";
}) {
  return (
    <button className={`button button--${variant} button--${size} ${className}`} {...props}>
      {children}
    </button>
  );
}

export function IconButton({ label, children, className = "", ...props }: React.ButtonHTMLAttributes<HTMLButtonElement> & { label: string; children: ReactNode }) {
  return (
    <button className={`icon-button ${className}`} aria-label={label} title={label} {...props}>
      {children}
    </button>
  );
}

export function Badge({ children, tone = "gray" }: { children: ReactNode; tone?: Tone }) {
  return <span className={`badge badge--${tone}`}>{children}</span>;
}

export function SceneBadge({ scene }: { scene: string }) {
  const tone: Tone = scene === "居家" ? "blue" : scene === "日间" ? "green" : scene === "住宿" ? "violet" : "amber";
  return <Badge tone={tone}>{scene}</Badge>;
}

export function PageHeader({ eyebrow, title, description, actions }: { eyebrow: string; title: string; description: string; actions?: ReactNode }) {
  return (
    <header className="page-header">
      <div>
        <div className="page-eyebrow">{eyebrow}</div>
        <h1>{title}</h1>
        <p>{description}</p>
      </div>
      {actions && <div className="page-actions">{actions}</div>}
    </header>
  );
}

export function SectionCard({ title, description, action, children, className = "" }: { title?: string; description?: string; action?: ReactNode; children: ReactNode; className?: string }) {
  return (
    <section className={`section-card ${className}`}>
      {(title || description || action) && (
        <div className="section-card__header">
          <div>
            {title && <h2>{title}</h2>}
            {description && <p>{description}</p>}
          </div>
          {action}
        </div>
      )}
      {children}
    </section>
  );
}

export function StatCard({ label, value, helper, icon, tone = "green" }: { label: string; value: string | number; helper: string; icon: ReactNode; tone?: Tone }) {
  return (
    <div className="stat-card">
      <div className={`stat-card__icon stat-card__icon--${tone}`}>{icon}</div>
      <div>
        <span>{label}</span>
        <strong>{value}</strong>
        <small>{helper}</small>
      </div>
    </div>
  );
}

export function SearchField({ value, onChange, placeholder = "搜索…" }: { value: string; onChange: (value: string) => void; placeholder?: string }) {
  return (
    <label className="search-field">
      <Search size={16} aria-hidden="true" />
      <input value={value} onChange={(event) => onChange(event.target.value)} placeholder={placeholder} />
      {value && (
        <button type="button" aria-label="清空搜索" onClick={() => onChange("")}>
          <X size={14} />
        </button>
      )}
    </label>
  );
}

export function Segmented<T extends string>({ items, value, onChange }: { items: readonly { value: T; label: string; count?: number }[]; value: T; onChange: (value: T) => void }) {
  return (
    <div className="segmented" role="tablist">
      {items.map((item) => (
        <button key={item.value} type="button" role="tab" aria-selected={value === item.value} className={value === item.value ? "is-active" : ""} onClick={() => onChange(item.value)}>
          {item.label}
          {item.count !== undefined && <span>{item.count}</span>}
        </button>
      ))}
    </div>
  );
}

export function Progress({ value, label }: { value: number; label?: string }) {
  return (
    <div className="progress-wrap">
      <div className="progress-track" aria-label={label} role="progressbar" aria-valuemin={0} aria-valuemax={100} aria-valuenow={value}>
        <span style={{ width: `${value}%` }} />
      </div>
      {label && <small>{label}</small>}
    </div>
  );
}

export function Field({ label, required, helper, children }: { label: string; required?: boolean; helper?: string; children: ReactNode }) {
  return (
    <label className="form-field">
      <span>{label}{required && <em>*</em>}</span>
      {children}
      {helper && <small>{helper}</small>}
    </label>
  );
}

export function Drawer({ open, title, description, children, onClose, footer }: { open: boolean; title: string; description: string; children: ReactNode; onClose: () => void; footer?: ReactNode }) {
  if (!open) return null;
  return (
    <div className="drawer-root" role="presentation">
      <button className="drawer-backdrop" aria-label="关闭抽屉" onClick={onClose} />
      <section className="drawer" role="dialog" aria-modal="true" aria-labelledby="drawer-title">
        <header className="drawer__header">
          <div>
            <h2 id="drawer-title">{title}</h2>
            <p>{description}</p>
          </div>
          <IconButton label="关闭" onClick={onClose}><X size={20} /></IconButton>
        </header>
        <div className="drawer__body">{children}</div>
        <footer className="drawer__footer">
          {footer ?? <><Button variant="secondary" onClick={onClose}>取消</Button><Button onClick={onClose}>保存演示内容</Button></>}
        </footer>
      </section>
    </div>
  );
}

export function EmptyState({ title, description }: { title: string; description: string }) {
  return <div className="empty-state"><strong>{title}</strong><p>{description}</p></div>;
}
