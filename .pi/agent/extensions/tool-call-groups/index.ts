import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  BranchSummaryMessageComponent,
  CompactionSummaryMessageComponent,
  getMarkdownTheme,
  ToolExecutionComponent,
  UserMessageComponent,
} from "@earendil-works/pi-coding-agent";
import {
  Container,
  Markdown,
  Text,
  truncateToWidth,
  visibleWidth,
  type Component,
  type MarkdownTheme,
} from "@earendil-works/pi-tui";

const PATCH_KEY = Symbol.for("kote.pi-tool-call-groups.patch.v1");
const DISPLAY_TEXT = "displayText";
const DISPLAY_TEXT_SCHEMA = {
  type: "string",
  minLength: 4,
  maxLength: 120,
  description:
    "Short present-tense account of what this call is meant to achieve, shown to the user after the call finishes streaming. Start with a verb and use 4-12 words.",
};

type ThemeLike = {
  fg(color: string, text: string): string;
  bold(text: string): string;
};

type ToolResultLike = {
  content?: Array<{ type?: string; text?: string; mimeType?: string }>;
  details?: unknown;
  isError?: boolean;
};

type ToolComponentLike = {
  toolName: string;
  toolCallId: string;
  args: Record<string, unknown>;
  expanded: boolean;
  isPartial: boolean;
  executionStarted: boolean;
  argsComplete: boolean;
  result?: ToolResultLike;
  resultRendererComponent?: Component;
  imageComponents?: Component[];
  ui?: { requestRender(): void };
  setExpanded(expanded: boolean): void;
};

type ObjectSchema = {
  properties?: Record<string, unknown>;
  required?: unknown;
  [key: string]: unknown;
};

type SchemaSnapshot = {
  schema: ObjectSchema;
  properties: Record<string, unknown>;
  hadDisplayText: boolean;
  displayTextValue?: unknown;
  hadRequired: boolean;
  requiredValue?: unknown;
};

type SummaryComponentLike = {
  expanded: boolean;
  message: { summary: string; tokensBefore?: number };
  markdownTheme?: MarkdownTheme;
  setExpanded(expanded: boolean): void;
};

type SummaryPrototype = {
  render(this: SummaryComponentLike, width: number): string[];
};

type UserMessageComponentLike = {
  text: string;
  markdownTheme: MarkdownTheme;
  outputPad: 0 | 1;
};

type UserMessagePrototype = {
  render(this: UserMessageComponentLike, width: number): string[];
};

type PatchState = {
  owner: object;
  originalContainerRender: (this: Container, width: number) => string[];
  originalCompactionRender: SummaryPrototype["render"];
  originalBranchRender: SummaryPrototype["render"];
  originalUserMessageRender: UserMessagePrototype["render"];
};

type GlobalWithPatch = typeof globalThis & {
  [PATCH_KEY]?: PatchState;
};

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function safeStringify(value: unknown, space = 2): string {
  const seen = new WeakSet<object>();
  try {
    return JSON.stringify(
      value,
      (_key, item: unknown) => {
        if (typeof item === "bigint") return `${item}n`;
        if (item !== null && typeof item === "object") {
          if (seen.has(item)) return "[Circular]";
          seen.add(item);
        }
        return item;
      },
      space,
    ) ?? String(value);
  } catch {
    return String(value);
  }
}

function oneLine(value: unknown, limit = 120): string {
  const raw = typeof value === "string" ? value : safeStringify(value, 0);
  const compact = raw.replace(/\s+/g, " ").trim();
  return compact.length <= limit ? compact : `${compact.slice(0, limit - 1)}…`;
}

function displayTextFor(component: ToolComponentLike): string {
  const value = component.args?.[DISPLAY_TEXT];
  if (typeof value === "string" && value.trim()) return value.trim();
  return `Run ${component.toolName}`;
}

function isComplete(component: ToolComponentLike, completedCalls: Set<string>): boolean {
  return (
    completedCalls.has(component.toolCallId) ||
    component.argsComplete ||
    component.executionStarted ||
    component.result !== undefined
  );
}

function statusFor(component: ToolComponentLike, theme: ThemeLike): string {
  if (component.result?.isError) return theme.fg("error", "×");
  if (component.isPartial || component.result === undefined) return theme.fg("accent", "●");
  return theme.fg("success", "✓");
}

function summarizeArguments(args: Record<string, unknown>): string {
  const entries = Object.entries(args).filter(([key]) => key !== DISPLAY_TEXT);
  if (entries.length === 0) return "no arguments";
  return entries
    .slice(0, 4)
    .map(([key, value]) => `${key}=${oneLine(value, 56)}`)
    .join(" · ") + (entries.length > 4 ? ` · +${entries.length - 4} more` : "");
}

function resultText(result: ToolResultLike | undefined): string {
  if (!result) return "";
  const parts: string[] = [];
  for (const block of result.content ?? []) {
    if (block.type === "text" && typeof block.text === "string") {
      parts.push(block.text);
    } else if (block.type === "image") {
      parts.push(`[image${block.mimeType ? `: ${block.mimeType}` : ""}]`);
    }
  }
  return parts.join("\n");
}

function toolTitle(component: ToolComponentLike, theme: ThemeLike): string {
  return `${statusFor(component, theme)} ${theme.fg("toolTitle", displayTextFor(component))}`;
}

function outputPadding(children: Component[]): 0 | 1 | undefined {
  for (const child of children) {
    const value = (child as Component & { outputPad?: unknown }).outputPad;
    if (value === 0 || value === 1) return value;
  }
  return undefined;
}

function outlinedBox(
  title: string,
  body: string[],
  width: number,
  padding: 0 | 1,
  theme: ThemeLike,
): string[] {
  if (width < 4) return body.map((line) => truncateToWidth(line, width, ""));

  const border = (text: string) => theme.fg("borderMuted", text);
  const innerWidth = width - 2;
  const label = title
    ? ` ${truncateToWidth(title, Math.max(0, innerWidth - 2), "")} `
    : "";
  const topFill = Math.max(0, innerWidth - visibleWidth(label));
  const horizontalPadding = Math.min(padding, Math.max(0, Math.floor((innerWidth - 1) / 2)));
  const contentWidth = Math.max(1, innerWidth - horizontalPadding * 2);
  const sidePadding = " ".repeat(horizontalPadding);
  const lines = [
    `${border("╭")}${label}${border("─".repeat(topFill))}${border("╮")}`,
  ];

  for (const line of body.length > 0 ? body : [""]) {
    const clipped = truncateToWidth(line, contentWidth, "");
    const fill = " ".repeat(Math.max(0, contentWidth - visibleWidth(clipped)));
    lines.push(
      `${border("│")}${sidePadding}${clipped}${fill}${sidePadding}${border("│")}`,
    );
  }

  lines.push(`${border("╰")}${border("─".repeat(innerWidth))}${border("╯")}`);
  return lines;
}

function expandedToolBody(
  component: ToolComponentLike,
  width: number,
  theme: ThemeLike,
): string[] {
  const content = new Container();
  const args = { ...component.args };
  delete args[DISPLAY_TEXT];
  content.addChild(
    new Text(
      `${theme.fg("dim", `${component.toolName} input`)}\n${theme.fg("toolOutput", safeStringify(args))}`,
      0,
      0,
    ),
  );

  if (component.resultRendererComponent) {
    content.addChild(component.resultRendererComponent);
  } else {
    const output = resultText(component.result);
    const details = component.result?.details;
    if (output) {
      content.addChild(
        new Text(`${theme.fg("dim", "result")}\n${theme.fg("toolOutput", output)}`, 0, 0),
      );
    }
    if (details !== undefined) {
      content.addChild(
        new Text(
          `${theme.fg("dim", "details")}\n${theme.fg("toolOutput", safeStringify(details))}`,
          0,
          0,
        ),
      );
    }
  }
  return content.render(width);
}

function renderToolGroup(
  components: ToolComponentLike[],
  width: number,
  level: number,
  completedCalls: Set<string>,
  theme: ThemeLike,
  padding: 0 | 1,
): string[] {
  const lines: string[] = [""];

  if (level === 0) {
    return [
      "",
      ...outlinedBox(
        "",
        components.map((component) => toolTitle(component, theme)),
        width,
        padding,
        theme,
      ),
    ];
  }

  for (const [index, component] of components.entries()) {
    if (index > 0) lines.push("");
    const bodyWidth = Math.max(1, width - 2 - padding * 2);
    let body: string[];
    if (level === 1) {
      const complete = isComplete(component, completedCalls);
      const detail = complete
        ? `${component.toolName} · ${summarizeArguments(component.args)}`
        : `${component.toolName} · preparing input`;
      const output = oneLine(resultText(component.result), 160);
      body = [theme.fg("dim", detail + (output ? ` · ${output}` : ""))];
    } else {
      body = expandedToolBody(component, bodyWidth, theme);
    }

    lines.push(...outlinedBox(toolTitle(component, theme), body, width, padding, theme));

    if (level === 2) {
      for (const image of component.imageComponents ?? []) {
        lines.push("", ...image.render(width));
      }
    }
  }
  return lines;
}

function renderSummaryBox(
  component: SummaryComponentLike,
  kind: "compaction" | "branch",
  width: number,
  padding: 0 | 1,
  theme: ThemeLike,
): string[] {
  const tokenText = component.message.tokensBefore?.toLocaleString();
  const titleText = kind === "compaction"
    ? `compaction${tokenText ? ` · ${tokenText} tokens` : ""}`
    : "branch summary";
  const title = theme.fg("customMessageLabel", titleText);
  const bodyWidth = Math.max(1, width - 2 - padding * 2);

  if (!component.expanded) {
    const text = kind === "compaction"
      ? "Context compacted · Alt+O to expand"
      : "Previous branch summarized · Alt+O to expand";
    return outlinedBox(title, [theme.fg("customMessageText", text)], width, padding, theme);
  }

  const markdown = new Markdown(
    component.message.summary,
    0,
    0,
    component.markdownTheme ?? getMarkdownTheme(),
    { color: (text) => theme.fg("customMessageText", text) },
  );
  return outlinedBox(title, markdown.render(bodyWidth), width, padding, theme);
}

function renderUserMessageBox(
  component: UserMessageComponentLike,
  width: number,
  theme: ThemeLike,
): string[] {
  if (width < 4) return [truncateToWidth(component.text, width, "")];

  const zoneStart = "\x1b]133;A\x07";
  const zoneEnd = "\x1b]133;B\x07\x1b]133;C\x07";
  const border = (text: string) => theme.fg("accent", text);
  const innerWidth = width - 2;
  const title = ` ${theme.bold(theme.fg("accent", "YOU"))} `;
  const fill = Math.max(0, innerWidth - visibleWidth(title));
  const markdown = new Markdown(
    component.text,
    component.outputPad,
    0,
    component.markdownTheme,
    { color: (text) => theme.fg("userMessageText", text) },
    { preserveOrderedListMarkers: true, preserveBackslashEscapes: true },
  );
  const body = markdown.render(innerWidth);
  const lines = [
    `${zoneStart}${border("┏")}${border("━")}${title}${border("━".repeat(Math.max(0, fill - 1)))}${border("┓")}`,
  ];

  for (const line of body) {
    const clipped = truncateToWidth(line, innerWidth, "");
    const remainder = Math.max(0, innerWidth - visibleWidth(clipped));
    lines.push(
      `${border("┃")}${clipped}${" ".repeat(remainder)}${border("┃")}`,
    );
  }

  lines.push(
    `${border("┗")}${border("━".repeat(innerWidth))}${border("┛")}${zoneEnd}`,
  );
  return lines;
}

type RenderPatchHandle = {
  dispose(): void;
  requestRender(): void;
  setExpanded(expanded: boolean): void;
};

function installRenderPatch(
  owner: object,
  getTheme: () => ThemeLike | undefined,
  getLevel: () => number,
  completedCalls: Set<string>,
): RenderPatchHandle | undefined {
  const globalWithPatch = globalThis as GlobalWithPatch;
  if (globalWithPatch[PATCH_KEY]) return undefined;

  const originalContainerRender = Container.prototype.render;
  const compactionPrototype = CompactionSummaryMessageComponent.prototype as unknown as SummaryPrototype;
  const branchPrototype = BranchSummaryMessageComponent.prototype as unknown as SummaryPrototype;
  const userMessagePrototype = UserMessageComponent.prototype as unknown as UserMessagePrototype;
  const originalCompactionRender = compactionPrototype.render;
  const originalBranchRender = branchPrototype.render;
  const originalUserMessageRender = userMessagePrototype.render;
  const seenTools = new Set<ToolComponentLike>();
  const seenSummaries = new Set<SummaryComponentLike>();
  const pendingExpansion = new WeakSet<ToolComponentLike>();
  let latestPadding: 0 | 1 = 1;
  let requestRender: (() => void) | undefined;

  const expandAfterRender = (tool: ToolComponentLike): void => {
    if (tool.expanded || pendingExpansion.has(tool)) return;
    pendingExpansion.add(tool);
    queueMicrotask(() => {
      pendingExpansion.delete(tool);
      if (getLevel() !== 2 || tool.expanded) return;
      tool.setExpanded(true);
      tool.ui?.requestRender();
    });
  };

  compactionPrototype.render = function outlinedCompactionRender(width: number): string[] {
    const theme = getTheme();
    if (!theme) return originalCompactionRender.call(this, width);
    seenSummaries.add(this);
    return renderSummaryBox(this, "compaction", width, latestPadding, theme);
  };

  branchPrototype.render = function outlinedBranchRender(width: number): string[] {
    const theme = getTheme();
    if (!theme) return originalBranchRender.call(this, width);
    seenSummaries.add(this);
    return renderSummaryBox(this, "branch", width, latestPadding, theme);
  };

  userMessagePrototype.render = function outlinedUserMessageRender(width: number): string[] {
    const theme = getTheme();
    if (!theme) return originalUserMessageRender.call(this, width);
    return renderUserMessageBox(this, width, theme);
  };

  Container.prototype.render = function groupedContainerRender(width: number): string[] {
    const theme = getTheme();
    const children = this.children;
    const configuredPadding = outputPadding(children);
    if (configuredPadding !== undefined) latestPadding = configuredPadding;
    if (!theme || !children.some((child) => child instanceof ToolExecutionComponent)) {
      return originalContainerRender.call(this, width);
    }

    const lines: string[] = [];
    let pendingTools: ToolComponentLike[] = [];

    const flushTools = (): void => {
      if (pendingTools.length === 0) return;
      lines.push(
        ...renderToolGroup(
          pendingTools,
          width,
          getLevel(),
          completedCalls,
          theme,
          latestPadding,
        ),
      );
      pendingTools = [];
    };

    for (const child of children) {
      if (child instanceof ToolExecutionComponent) {
        const tool = child as unknown as ToolComponentLike;
        pendingTools.push(tool);
        seenTools.add(tool);
        if (getLevel() === 2) expandAfterRender(tool);
        if (tool.ui?.requestRender) {
          requestRender = () => tool.ui?.requestRender();
        }
        continue;
      }

      const childLines = child.render(width);
      if (pendingTools.length > 0 && childLines.length === 0) {
        // A tool-only assistant message renders no lines. Ignore it so calls on
        // either side remain one group until visible assistant text appears.
        continue;
      }

      flushTools();
      lines.push(...childLines);
    }

    flushTools();
    return lines;
  };

  globalWithPatch[PATCH_KEY] = {
    owner,
    originalContainerRender,
    originalCompactionRender,
    originalBranchRender,
    originalUserMessageRender,
  };

  return {
    dispose() {
      const current = globalWithPatch[PATCH_KEY];
      if (current?.owner !== owner) return;
      Container.prototype.render = current.originalContainerRender;
      compactionPrototype.render = current.originalCompactionRender;
      branchPrototype.render = current.originalBranchRender;
      userMessagePrototype.render = current.originalUserMessageRender;
      delete globalWithPatch[PATCH_KEY];
      seenTools.clear();
      seenSummaries.clear();
      requestRender = undefined;
    },
    requestRender() {
      requestRender?.();
    },
    setExpanded(expanded: boolean) {
      for (const tool of seenTools) tool.setExpanded(expanded);
      for (const summary of seenSummaries) summary.setExpanded(expanded);
    },
  };
}

function addDisplayTextToSchema(
  schemaValue: unknown,
  snapshots: SchemaSnapshot[],
): boolean {
  const schema = asRecord(schemaValue) as ObjectSchema;
  const properties = asRecord(schema.properties);
  if (schema.type !== "object" || Object.keys(properties).length === 0) return false;

  const hadDisplayText = Object.prototype.hasOwnProperty.call(properties, DISPLAY_TEXT);
  if (hadDisplayText) return false;

  snapshots.push({
    schema,
    properties,
    hadDisplayText,
    displayTextValue: properties[DISPLAY_TEXT],
    hadRequired: Object.prototype.hasOwnProperty.call(schema, "required"),
    requiredValue: schema.required,
  });

  properties[DISPLAY_TEXT] = { ...DISPLAY_TEXT_SCHEMA };
  const required = Array.isArray(schema.required)
    ? schema.required.filter((item): item is string => typeof item === "string")
    : [];
  schema.required = [...required, DISPLAY_TEXT];
  return true;
}

function restoreSchemas(snapshots: SchemaSnapshot[]): void {
  for (const snapshot of snapshots.reverse()) {
    if (snapshot.hadDisplayText) {
      snapshot.properties[DISPLAY_TEXT] = snapshot.displayTextValue;
    } else {
      delete snapshot.properties[DISPLAY_TEXT];
    }
    if (snapshot.hadRequired) {
      snapshot.schema.required = snapshot.requiredValue;
    } else {
      delete snapshot.schema.required;
    }
  }
  snapshots.length = 0;
}

export default function toolCallGroups(pi: ExtensionAPI): void {
  const owner = {};
  const completedCalls = new Set<string>();
  const snapshots: SchemaSnapshot[] = [];
  const decoratedSchemas = new WeakSet<object>();
  const schemasWithInjectedDisplayText = new WeakSet<object>();
  const decoratedSchemaByToolName = new Map<string, object>();
  let activeTheme: ThemeLike | undefined;
  let expansionLevel = 0;

  const decorateKnownTools = (): void => {
    let tools: ReturnType<ExtensionAPI["getAllTools"]>;
    try {
      tools = pi.getAllTools();
    } catch {
      return;
    }

    for (const tool of tools) {
      if (!tool.parameters || typeof tool.parameters !== "object") continue;
      const schema = tool.parameters as object;
      if (!decoratedSchemas.has(schema)) {
        decoratedSchemas.add(schema);
        if (addDisplayTextToSchema(tool.parameters, snapshots)) {
          schemasWithInjectedDisplayText.add(schema);
        }
      }

      if (schemasWithInjectedDisplayText.has(schema)) {
        decoratedSchemaByToolName.set(tool.name, schema);
      } else if (decoratedSchemaByToolName.get(tool.name) !== schema) {
        decoratedSchemaByToolName.delete(tool.name);
      }
    }
  };

  const renderPatch = installRenderPatch(
    owner,
    () => activeTheme,
    () => expansionLevel,
    completedCalls,
  );

  pi.registerShortcut("alt+o", {
    description: "Expand grouped tool calls",
    handler: async () => {
      expansionLevel = Math.min(2, expansionLevel + 1);
      renderPatch?.setExpanded(expansionLevel === 2);
      renderPatch?.requestRender();
    },
  });

  pi.registerShortcut("alt+i", {
    description: "Collapse grouped tool calls",
    handler: async () => {
      expansionLevel = Math.max(0, expansionLevel - 1);
      renderPatch?.setExpanded(expansionLevel === 2);
      renderPatch?.requestRender();
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    activeTheme = ctx.ui.theme as unknown as ThemeLike;
    completedCalls.clear();
    decorateKnownTools();
  });

  pi.on("before_agent_start", async () => {
    decorateKnownTools();
  });

  pi.on("message_update", async (event) => {
    if (event.message.role !== "assistant") return;
    const streamEvent = event.assistantMessageEvent;
    if (streamEvent.type === "toolcall_end") {
      completedCalls.add(streamEvent.toolCall.id);
    }
  });

  pi.on("message_end", async (event) => {
    if (event.message.role !== "assistant") return;
    for (const content of event.message.content) {
      if (content.type === "toolCall") completedCalls.add(content.id);
    }
  });

  pi.on("tool_call", async (event) => {
    if (!decoratedSchemaByToolName.has(event.toolName)) return;
    // Validation has already run. Pi guarantees that tool_call mutations are
    // passed to execute without another validation pass, while the assistant
    // message keeps the original arguments for rendering and session replay.
    delete (event.input as Record<string, unknown>)[DISPLAY_TEXT];
  });

  pi.on("tool_result", async () => {
    // Tools may register more tools during execution.
    decorateKnownTools();
  });

  pi.on("session_shutdown", async () => {
    renderPatch?.dispose();
    restoreSchemas(snapshots);
    activeTheme = undefined;
    completedCalls.clear();
  });
}
