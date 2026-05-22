"use client";

import { useEffect, useMemo, useState } from "react";

type Room = { _id: string; name: string; admin?: string; isPublic?: boolean };
type Message = {
  _id: string;
  sender: string;
  senderName?: string;
  message?: string;
  fileUrl?: string;
  createdAt: string;
};
type Member = {
  _id: string;
  username: string;
  email?: string;
  isGroupCreator?: boolean;
};

function isImageUrl(url: string) {
  const u = url.toLowerCase();
  return (
    u.includes("image/") ||
    /\.(jpg|jpeg|png|gif|webp|bmp)(\?|$)/i.test(u) ||
    u.includes("res.cloudinary.com")
  );
}

export default function CommunityModerationPage() {
  const [rooms, setRooms] = useState<Room[]>([]);
  const [messages, setMessages] = useState<Message[]>([]);
  const [members, setMembers] = useState<Member[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [roomId, setRoomId] = useState<string>("");
  const [lightboxUrl, setLightboxUrl] = useState<string | null>(null);

  const selectedRoom = useMemo(
    () => rooms.find((r) => r._id === roomId) ?? null,
    [rooms, roomId],
  );

  async function refreshRooms() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/community", { cache: "no-store" });
      const j = (await res.json()) as any;
      if (!res.ok) {
        setRooms([]);
        setMessages([]);
        setError(j?.error ?? "Failed to load chat rooms");
        return;
      }
      const nextRooms = (j?.rooms ?? []) as Room[];
      setRooms(nextRooms);
      if (!roomId && nextRooms.length > 0) setRoomId(nextRooms[0]._id);
      if (nextRooms.length === 0) {
        setMessages([]);
        setMembers([]);
      }
    } catch {
      setError("Failed to load chat rooms");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refreshRooms();
  }, []);

  async function refreshMessages(nextRoomId: string) {
    setError(null);
    setLoading(true);
    try {
      const res = await fetch(
        `/api/admin/community/rooms/${nextRoomId}/messages`,
        { cache: "no-store" },
      );
      const j = (await res.json().catch(() => null)) as any;
      if (!res.ok) {
        setMessages([]);
        setError(j?.error ?? "Failed to load room messages");
        return;
      }
      const ms = (j?.messages ?? j?.data?.messages ?? j?.data ?? []) as any[];
      setMessages(
        ms.map((m) => ({
          _id: m._id,
          sender: m.sender,
          senderName: m.senderName,
          message: m.message,
          fileUrl: typeof m.fileUrl === "string" ? m.fileUrl : undefined,
          createdAt: m.createdAt,
        })),
      );
      const memRes = await fetch(`/api/admin/community/rooms/${nextRoomId}/members`, {
        cache: "no-store",
      });
      const memJson = (await memRes.json().catch(() => null)) as any;
      if (!memRes.ok) {
        setMembers([]);
      } else {
        const list = (memJson?.members ?? memJson?.data?.members ?? []) as Member[];
        setMembers(Array.isArray(list) ? list : []);
      }
    } catch {
      setError("Failed to load room messages");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (roomId) refreshMessages(roomId);
  }, [roomId]);

  async function removeMessage(id: string) {
    if (!confirm("Remove this message?")) return;
    setError(null);
    const res = await fetch(`/api/admin/community/messages/${id}`, {
      method: "DELETE",
    });
    if (!res.ok) setError("Remove failed");
    if (roomId) await refreshMessages(roomId);
  }

  async function blockUser(memberId: string) {
    if (
      !confirm(
        "Block and delete this user? This will remove their account, listings, community messages, groups they created, and AI chats.",
      )
    )
      return;
    setError(null);
    const res = await fetch(`/api/admin/users/${memberId}/block`, {
      method: "DELETE",
    });
    const j = (await res.json().catch(() => null)) as { error?: string } | null;
    if (!res.ok) {
      setError(j?.error ?? "Block failed");
      return;
    }
    await refreshMessages(roomId);
  }

  return (
    <div className="space-y-5">
      <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
        <h1 className="text-xl font-semibold tracking-tight">
          Community & chat moderation
        </h1>
        <p className="mt-2 text-sm leading-7 text-zinc-700">
          monitor chat remove chat or block members
        </p>
      </div>

      <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="text-sm font-semibold">
            Messages {selectedRoom ? `— ${selectedRoom.name}` : ""}
          </div>
          <div className="flex flex-col gap-1">
            <div className="text-xs font-semibold uppercase tracking-wide text-zinc-600">
              Rooms
            </div>
            <div className="flex items-center gap-2">
            <select
              value={roomId}
              onChange={(e) => setRoomId(e.target.value)}
              className="rounded-2xl border border-black/10 bg-white px-3 py-2 text-sm"
            >
              {rooms.map((r) => (
                <option key={r._id} value={r._id}>
                  {r.name}
                </option>
              ))}
            </select>
            <button
              onClick={() => refreshRooms()}
              className="rounded-full border border-black/10 bg-white px-4 py-2 text-sm font-semibold hover:bg-black/5"
            >
              Refresh
            </button>
            </div>
          </div>
        </div>

        {error ? (
          <div className="mt-4 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
            {error}
          </div>
        ) : null}

        {loading ? (
          <div className="mt-4 text-sm text-zinc-600">Loading...</div>
        ) : rooms.length === 0 ? (
          <div className="mt-4 text-sm text-zinc-600">No data.</div>
        ) : (
          <div className="mt-4 overflow-x-auto">
            <table className="w-full min-w-[960px] text-left text-sm">
              <thead className="text-xs text-zinc-600">
                <tr>
                  <th className="py-2">Sender</th>
                  <th>Content</th>
                  <th>Time</th>
                  <th className="text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="align-top">
                {messages.map((m) => {
                  const img =
                    m.fileUrl && isImageUrl(m.fileUrl) ? m.fileUrl : null;
                  return (
                    <tr key={m._id} className="border-t border-black/5">
                      <td className="text-zinc-700">
                        <div className="py-3 font-medium">
                          {m.senderName ?? m.sender}
                        </div>
                        <div className="text-xs text-zinc-500">{m.sender}</div>
                      </td>
                      <td className="text-zinc-700">
                        {m.message ? (
                          <div className="max-w-md whitespace-pre-wrap">
                            {m.message}
                          </div>
                        ) : null}
                        {img ? (
                          <button
                            type="button"
                            onClick={() => setLightboxUrl(img)}
                            className="mt-2 block rounded-xl border border-black/10 bg-zinc-50 p-1 text-left hover:border-emerald-600/40"
                          >
                            {/* eslint-disable-next-line @next/next/no-img-element */}
                            <img
                              src={img}
                              alt="Attachment"
                              className="h-20 w-20 rounded-lg object-cover"
                            />
                            <span className="mt-1 block px-1 pb-1 text-xs font-semibold text-emerald-800">
                              Tap to enlarge
                            </span>
                          </button>
                        ) : m.fileUrl ? (
                          <a
                            className="mt-2 inline-block text-xs font-semibold text-emerald-700 underline"
                            href={m.fileUrl}
                            target="_blank"
                            rel="noreferrer"
                          >
                            Open attachment
                          </a>
                        ) : !m.message ? (
                          <span className="text-zinc-500">(no content)</span>
                        ) : null}
                      </td>
                      <td className="text-zinc-700">
                        {new Date(m.createdAt).toLocaleString()}
                      </td>
                      <td className="text-right">
                        <div className="inline-flex items-center gap-2">
                          <button
                            onClick={() => removeMessage(m._id)}
                            className="rounded-full border border-red-200 bg-red-50 px-3 py-1.5 text-xs font-semibold text-red-800 hover:bg-red-100"
                          >
                            Remove
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
                {messages.length === 0 ? (
                  <tr>
                    <td className="py-6 text-sm text-zinc-600" colSpan={4}>
                      No messages in this room.
                    </td>
                  </tr>
                ) : null}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <div className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm">
        <div className="text-sm font-semibold">Room members</div>
        <div className="mt-4 grid gap-3 md:grid-cols-2">
          {members.map((m) => (
            <div
              key={m._id}
              className="flex items-center justify-between rounded-3xl border border-black/5 bg-zinc-50 p-4"
            >
              <div>
                <div className="text-sm font-semibold">{m.username}</div>
                <div className="text-xs text-zinc-600">{m.email ?? m._id}</div>
              </div>
              <button
                disabled={Boolean(m.isGroupCreator)}
                onClick={() => blockUser(m._id)}
                className="rounded-full border border-red-200 bg-red-50 px-4 py-2 text-xs font-semibold text-red-800 hover:bg-red-100 disabled:opacity-40"
              >
                {m.isGroupCreator ? "Creator" : "Block user"}
              </button>
            </div>
          ))}
          {members.length === 0 ? (
            <div className="text-sm text-zinc-600">No members found for this room.</div>
          ) : null}
        </div>
      </div>

      {lightboxUrl ? (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4"
          role="dialog"
          aria-modal="true"
          onClick={() => setLightboxUrl(null)}
        >
          <div
            className="max-h-[92vh] max-w-5xl overflow-auto rounded-2xl bg-white p-3 shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={lightboxUrl}
              alt="Full size"
              className="max-h-[88vh] w-auto max-w-full object-contain"
            />
            <div className="mt-3 flex justify-end">
              <button
                type="button"
                className="rounded-full bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-700"
                onClick={() => setLightboxUrl(null)}
              >
                Close
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
