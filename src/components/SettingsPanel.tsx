import { ArrowLeft, Gauge, Palette, Settings, X } from "lucide-react";
import {
  type PracticeModeId,
  type ProficiencyId,
  practiceModes,
  proficiencyLevels
} from "../domain/practice";
import { zoom } from "../state/sessionStore";

interface SettingsPanelProps {
  contentScale: number;
  isOpen: boolean;
  mode: PracticeModeId;
  proficiency: ProficiencyId;
  onChangeMode: (mode: PracticeModeId) => void;
  onChangeProficiency: (proficiency: ProficiencyId) => void;
  onClose: () => void;
  onResetZoom: () => void;
  onSetContentScale: (value: number) => void;
}

export function SettingsPanel({
  contentScale,
  isOpen,
  mode,
  proficiency,
  onChangeMode,
  onChangeProficiency,
  onClose,
  onResetZoom,
  onSetContentScale
}: SettingsPanelProps) {
  return (
    <div className={isOpen ? "settings-layer open" : "settings-layer"} aria-hidden={!isOpen}>
      <div className="settings-scrim" onClick={onClose} />
      <aside className="settings-panel" aria-label="Settings">
        <div className="settings-titlebar">
          <h2>Settings</h2>
          <button className="icon-button" type="button" onClick={onClose} aria-label="Close">
            <X size={18} />
          </button>
        </div>

        <button className="back-button" type="button" onClick={onClose}>
          <ArrowLeft size={18} />
          Back to app
        </button>

        <nav className="settings-nav" aria-label="Settings sections">
          <button className="selected" type="button">
            <Settings size={18} />
            General
          </button>
          <button type="button">
            <Palette size={18} />
            Appearance
          </button>
        </nav>

        <section className="settings-section">
          <div className="section-heading">
            <h3>Current chat</h3>
            <p>Adjust how this practice session behaves.</p>
          </div>

          <label className="select-control panel-select">
            <span>Mode</span>
            <select
              value={mode}
              onChange={(event) => onChangeMode(event.target.value as PracticeModeId)}
            >
              {practiceModes.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.title}
                </option>
              ))}
            </select>
          </label>

          <label className="select-control panel-select">
            <span>Level</span>
            <select
              value={proficiency}
              onChange={(event) =>
                onChangeProficiency(event.target.value as ProficiencyId)
              }
            >
              {proficiencyLevels.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.title}
                </option>
              ))}
            </select>
          </label>
        </section>

        <section className="settings-section">
          <div className="section-heading">
            <h3>Interface</h3>
            <p>Tune the reading size across chats and controls.</p>
          </div>

          <label className="zoom-control">
            <span className="zoom-label">
              <Gauge size={17} />
              Content zoom
            </span>
            <span className="zoom-value">{Math.round(contentScale * 100)}%</span>
            <input
              type="range"
              min={zoom.minimum}
              max={zoom.maximum}
              step={zoom.step}
              value={contentScale}
              onChange={(event) => onSetContentScale(Number(event.target.value))}
            />
          </label>

          <button className="secondary-button" type="button" onClick={onResetZoom}>
            Reset
          </button>
        </section>
      </aside>
    </div>
  );
}
