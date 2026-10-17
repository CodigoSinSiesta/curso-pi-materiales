import { createAgentSession, SessionManager } from "@earendil-works/pi-coding-agent";

const cwd = process.argv[2] ?? process.cwd();
const { session } = await createAgentSession({
  cwd,
  tools: ["read", "grep", "find", "ls"],
  sessionManager: SessionManager.inMemory(cwd),
});

session.subscribe((evento) => {
  if (evento.type === "tool_execution_start") console.error(`[${evento.toolName}]`);
});

try {
  await session.prompt("Lista las funciones exportadas de src, una por línea, con su fichero.");
  console.log(session.getLastAssistantText());
} finally {
  session.dispose();
}
