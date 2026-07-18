import { useState } from "react";
import { Building2, CheckCircle2, ClipboardCheck, Edit3, Info, MapPin, UsersRound } from "lucide-react";
import { capabilities, institution, modulePreferences } from "@anyangtai/demo-data";
import { Badge, Button, Drawer, Field, PageHeader, Progress, SectionCard, StatCard } from "../components/Ui";

export function InstitutionPage() {
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [modules, setModules] = useState<Record<string, boolean>>(() => Object.fromEntries(modulePreferences.map((item) => [item.key, item.enabled])));

  return (
    <>
      <PageHeader
        eyebrow="基础配置 / 机构资料"
        title="机构资料配置"
        description="机构自主维护经营资料和服务能力，系统只提供非阻断的政策与完整性提示。"
        actions={<><Button variant="secondary"><ClipboardCheck size={16} />资料检查</Button><Button onClick={() => setDrawerOpen(true)}><Edit3 size={16} />编辑机构资料</Button></>}
      />

      <div className="stats-grid stats-grid--4">
        <StatCard label="资料完整度" value="88%" helper="还有 3 项建议补充" icon={<CheckCircle2 size={19} />} />
        <StatCard label="已启用服务场景" value={institution.enabledSceneCount} helper="四类场景均已开启" icon={<Building2 size={19} />} tone="blue" />
        <StatCard label="在职员工" value={institution.activeStaffCount} helper="含 2 名兼职人员" icon={<UsersRound size={19} />} tone="violet" />
        <StatCard label="正式养老床位" value={institution.formalBedCount} helper="由机构自行维护" icon={<MapPin size={19} />} tone="amber" />
      </div>

      <div className="content-grid content-grid--institution">
        <SectionCard title="机构基本资料" description="用于日常经营、协议和后续数据对接的机构稳定信息。" action={<Badge tone="green">{institution.status}</Badge>}>
          <div className="institution-identity">
            <div className="institution-mark">云栖</div>
            <div>
              <h3>{institution.name}</h3>
              <p>{institution.code} · {institution.nature}</p>
            </div>
          </div>
          <dl className="details-grid">
            <div><dt>运营性质</dt><dd>{institution.operatorType}</dd></div>
            <div><dt>统一社会信用代码</dt><dd>{institution.unifiedCreditCode}</dd></div>
            <div><dt>法定代表人</dt><dd>{institution.legalRepresentative}</dd></div>
            <div><dt>联系电话</dt><dd>{institution.phone}</dd></div>
            <div className="details-grid__wide"><dt>机构地址</dt><dd>{institution.address}</dd></div>
            <div><dt>成立日期</dt><dd>{institution.establishedOn}</dd></div>
          </dl>
          <div className="completion-box">
            <div><strong>资料完整度 88%</strong><span>建议补充消防验收、食品经营和机构备案资料</span></div>
            <Progress value={88} />
          </div>
        </SectionCard>

        <SectionCard title="政策与经营提示" description="只在页面内提示，不弹窗、不阻断保存。">
          <div className="policy-notice">
            <div className="policy-notice__icon"><Info size={20} /></div>
            <div>
              <Badge tone="amber">建议关注</Badge>
              <h3>正式养老床位超过 10 张</h3>
              <p>当前机构配置了 {institution.formalBedCount} 张正式养老床位。建议根据属地要求确认养老机构备案事项，并留存相关材料。</p>
              <button type="button">查看需要准备的资料清单 →</button>
            </div>
          </div>
          <div className="notice-list">
            <div><CheckCircle2 size={17} /><span><strong>服务能力由机构自主选择</strong><small>系统不代替行政认定，也不会锁定功能。</small></span></div>
            <div><CheckCircle2 size={17} /><span><strong>第三方评估机构模式未启用</strong><small>本系统只保存外部评估结论和附件。</small></span></div>
          </div>
        </SectionCard>
      </div>

      <SectionCard title="服务能力" description="能力选择用于推荐默认功能和资料模板，之后仍可自由调整。">
        <div className="capability-grid">
          {capabilities.map((capability) => (
            <article className="capability-card" key={capability.key}>
              <div className={`scene-symbol scene-symbol--${capability.key}`}>{capability.name.slice(0, 1)}</div>
              <div className="capability-card__body">
                <div><h3>{capability.name}</h3><Badge tone="green">已启用</Badge></div>
                <p>{capability.summary}</p>
                <span>{capability.metric}</span>
              </div>
            </article>
          ))}
        </div>
      </SectionCard>

      <SectionCard title="功能模块" description="系统根据服务能力给出推荐，机构可随时开启或关闭；不存在“必需依赖”或强制锁定。">
        <div className="module-table">
          {modulePreferences.map((module) => (
            <div className="module-row" key={module.key}>
              <div><strong>{module.name}</strong><small>{module.group}</small></div>
              <div>{module.recommended ? <Badge tone="blue">系统推荐</Badge> : <Badge>可选</Badge>}</div>
              <button
                type="button"
                role="switch"
                aria-checked={modules[module.key]}
                className={`switch ${modules[module.key] ? "is-on" : ""}`}
                onClick={() => setModules((current) => ({ ...current, [module.key]: !current[module.key] }))}
              ><span /></button>
            </div>
          ))}
        </div>
      </SectionCard>

      <Drawer open={drawerOpen} onClose={() => setDrawerOpen(false)} title="编辑机构资料" description="修改只作用于当前匿名演示数据，关闭抽屉不会保存。">
        <div className="form-section">
          <div className="form-section__title"><span>1</span><div><h3>机构身份</h3><p>机构长期稳定且用于协议展示的信息</p></div></div>
          <div className="form-grid">
            <Field label="机构全称" required><input defaultValue={institution.name} /></Field>
            <Field label="机构简称"><input defaultValue={institution.shortName} /></Field>
            <Field label="机构性质" required><select defaultValue={institution.nature}><option>民办非企业单位</option><option>企业</option><option>事业单位</option></select></Field>
            <Field label="运营性质"><select defaultValue={institution.operatorType}><option>社会力量运营</option><option>公建民营</option><option>政府运营</option></select></Field>
            <Field label="统一社会信用代码" required><input defaultValue="91320500DEMO0015X" /></Field>
            <Field label="法定代表人"><input defaultValue="周明远" /></Field>
          </div>
        </div>
        <div className="form-section">
          <div className="form-section__title"><span>2</span><div><h3>联系方式</h3><p>用于业务联系和文书展示</p></div></div>
          <div className="form-grid">
            <Field label="机构联系电话"><input defaultValue="0512-88102616" /></Field>
            <Field label="成立日期"><input type="date" defaultValue={institution.establishedOn} /></Field>
            <Field label="详细地址" required><input defaultValue={institution.address} /></Field>
            <Field label="机构简介"><textarea defaultValue="面向周边社区提供居家上门、日间照料、小规模住宿和喘息服务。" /></Field>
          </div>
        </div>
      </Drawer>
    </>
  );
}
