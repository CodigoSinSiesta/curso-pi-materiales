import { createAgentSession, SessionManager } from "@oh-my-pi/pi-coding-agent";

const cwd = process.argv[2] ?? process.cwd();
const { session } = await createAgentSession({
  cwd,
  toolNames: ["read", "grep", "glob"],
  restrictToolNames: true,
  sessionManager: SessionManager.inMemory(),
});

session.subscribe((evento) => {
  if (evento.type === "tool_execution_start") console.error(`[${evento.toolName}]`);
});

try {
  await session.prompt("Lista las funciones exportadas de src, una por línea, con su fichero.");
  console.log(session.getLastAssistantText());
} finally {
  await session.dispose();
}
