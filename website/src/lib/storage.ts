import { promises as fs } from "node:fs";
import path from "node:path";

export const runtime = "nodejs";

function dataPath(name: string) {
  return path.join(process.cwd(), "data", name);
}

async function ensureDataDir() {
  await fs.mkdir(path.join(process.cwd(), "data"), { recursive: true });
}

export async function readJson<T>(name: string, fallback: T): Promise<T> {
  await ensureDataDir();
  const p = dataPath(name);
  try {
    const raw = await fs.readFile(p, "utf8");
    return JSON.parse(raw) as T;
  } catch {
    await fs.writeFile(p, JSON.stringify(fallback, null, 2), "utf8");
    return fallback;
  }
}

export async function writeJson<T>(name: string, value: T): Promise<void> {
  await ensureDataDir();
  const p = dataPath(name);
  await fs.writeFile(p, JSON.stringify(value, null, 2), "utf8");
}

