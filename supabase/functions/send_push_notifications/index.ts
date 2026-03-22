/**
 * Wave 5 Track B — fan out pending notification_events to OneSignal (Android active; iOS stubbed).
 *
 * Secrets: ONESIGNAL_APP_ID, ONESIGNAL_REST_API_KEY (Supabase Edge secrets)
 * Optional: IOS_PUSH_ENABLED=true, PUSH_BATCH_SIZE=50, PUSH_MAX_ATTEMPTS=5
 */
import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

type NotificationEvent = {
  id: string;
  school_id: string;
  target_user_id: string;
  event_type: string;
  title: string;
  body: string;
  payload: Record<string, unknown>;
  attempt_count: number;
};

type DeviceTokenRow = {
  id: string;
  token: string;
  platform: "ios" | "android";
};

const IOS_PUSH_ENABLED = Deno.env.get("IOS_PUSH_ENABLED") === "true";
const BATCH_SIZE = Math.min(
  200,
  Math.max(1, parseInt(Deno.env.get("PUSH_BATCH_SIZE") ?? "50", 10) || 50),
);
const MAX_ATTEMPTS = Math.min(
  20,
  Math.max(1, parseInt(Deno.env.get("PUSH_MAX_ATTEMPTS") ?? "5", 10) || 5),
);

function requireEnv(name: string): string {
  const v = Deno.env.get(name);
  if (!v) throw new Error(`Missing required secret: ${name}`);
  return v;
}

async function sendOneSignalNotification(params: {
  appId: string;
  restApiKey: string;
  subscriptionIds: string[];
  title: string;
  body: string;
  data: Record<string, unknown>;
}): Promise<{ ok: boolean; status: number; json: Record<string, unknown> }> {
  const res = await fetch("https://api.onesignal.com/notifications", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Key ${params.restApiKey}`,
    },
    body: JSON.stringify({
      app_id: params.appId,
      include_subscription_ids: params.subscriptionIds,
      headings: { en: params.title },
      contents: { en: params.body },
      data: params.data,
    }),
  });
  const json = (await res.json()) as Record<string, unknown>;
  return { ok: res.ok, status: res.status, json };
}

async function insertDelivery(
  supabase: SupabaseClient,
  row: {
    event_id: string;
    token_id: string;
    status: "sent" | "failed" | "invalid_token" | "skipped";
    provider_message_id?: string | null;
    provider_response: Record<string, unknown>;
    error_code?: string | null;
    error_message?: string | null;
  },
) {
  const { error } = await supabase.from("notification_deliveries").insert({
    event_id: row.event_id,
    token_id: row.token_id,
    status: row.status,
    provider_message_id: row.provider_message_id ?? null,
    provider_response: row.provider_response,
    error_code: row.error_code ?? null,
    error_message: row.error_message ?? null,
  });
  if (error) throw error;
}

async function finalizeEvent(
  supabase: SupabaseClient,
  eventId: string,
  patch: {
    status: "sent" | "failed" | "discarded";
    last_error?: string | null;
  },
) {
  const { error } = await supabase
    .from("notification_events")
    .update({
      status: patch.status,
      last_error: patch.last_error ?? null,
      processed_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq("id", eventId);
  if (error) throw error;
}

async function processEvent(
  supabase: SupabaseClient,
  event: NotificationEvent,
  onesignalAppId: string,
  onesignalRestKey: string,
) {
  const { data: tokens, error: tokErr } = await supabase
    .from("device_tokens")
    .select("id, token, platform")
    .eq("user_id", event.target_user_id)
    .eq("school_id", event.school_id);

  if (tokErr) throw tokErr;

  const rows = (tokens ?? []) as DeviceTokenRow[];
  if (rows.length === 0) {
    await finalizeEvent(supabase, event.id, {
      status: "discarded",
      last_error: "no_device_tokens",
    });
    console.log(
      JSON.stringify({
        level: "info",
        event_id: event.id,
        outcome: "discarded",
        reason: "no_device_tokens",
      }),
    );
    return;
  }

  let sentCount = 0;
  let skippedCount = 0;
  let failedSendCount = 0;

  for (const row of rows) {
    if (row.platform === "ios" && !IOS_PUSH_ENABLED) {
      skippedCount++;
      await insertDelivery(supabase, {
        event_id: event.id,
        token_id: row.id,
        status: "skipped",
        provider_response: { reason: "ios_push_disabled" },
        error_message: "iOS push disabled (Wave 5 stub)",
      });
      continue;
    }

    if (row.platform === "ios" && IOS_PUSH_ENABLED) {
      const result = await sendOneSignalNotification({
        appId: onesignalAppId,
        restApiKey: onesignalRestKey,
        subscriptionIds: [row.token],
        title: event.title,
        body: event.body,
        data: {
          ...event.payload,
          event_id: event.id,
          school_id: event.school_id,
          event_type: event.event_type,
        },
      });
      const msgId =
        typeof result.json["id"] === "string"
          ? (result.json["id"] as string)
          : null;
      if (result.ok) {
        sentCount++;
        await insertDelivery(supabase, {
          event_id: event.id,
          token_id: row.id,
          status: "sent",
          provider_message_id: msgId,
          provider_response: result.json,
        });
      } else {
        failedSendCount++;
        const errText = JSON.stringify(result.json);
        await insertDelivery(supabase, {
          event_id: event.id,
          token_id: row.id,
          status: "failed",
          provider_response: result.json,
          error_code: String(result.status),
          error_message: errText.slice(0, 2000),
        });
      }
      continue;
    }

    // Android (active)
    const result = await sendOneSignalNotification({
      appId: onesignalAppId,
      restApiKey: onesignalRestKey,
      subscriptionIds: [row.token],
      title: event.title,
      body: event.body,
      data: {
        ...event.payload,
        event_id: event.id,
        school_id: event.school_id,
        event_type: event.event_type,
      },
    });
    const msgId =
      typeof result.json["id"] === "string"
        ? (result.json["id"] as string)
        : null;

    if (result.ok) {
      sentCount++;
      await insertDelivery(supabase, {
        event_id: event.id,
        token_id: row.id,
        status: "sent",
        provider_message_id: msgId,
        provider_response: result.json,
      });
      continue;
    }

    const errors = result.json["errors"];
    const invalid =
      result.status === 400 &&
      typeof errors === "object" &&
      errors !== null &&
      JSON.stringify(errors).includes("invalid");

    if (invalid) {
      await supabase.from("device_tokens").delete().eq("id", row.id);
      await insertDelivery(supabase, {
        event_id: event.id,
        token_id: row.id,
        status: "invalid_token",
        provider_response: result.json,
        error_code: String(result.status),
        error_message: "invalid_subscription_or_token",
      });
      failedSendCount++;
    } else {
      failedSendCount++;
      await insertDelivery(supabase, {
        event_id: event.id,
        token_id: row.id,
        status: "failed",
        provider_response: result.json,
        error_code: String(result.status),
        error_message: JSON.stringify(result.json).slice(0, 2000),
      });
    }
  }

  if (sentCount > 0) {
    await finalizeEvent(supabase, event.id, { status: "sent", last_error: null });
  } else if (skippedCount === rows.length && failedSendCount === 0) {
    await finalizeEvent(supabase, event.id, {
      status: "discarded",
      last_error: "all_tokens_skipped_ios_disabled",
    });
  } else if (failedSendCount > 0) {
    await finalizeEvent(supabase, event.id, {
      status: "failed",
      last_error: "all_deliveries_failed",
    });
  } else {
    await finalizeEvent(supabase, event.id, {
      status: "discarded",
      last_error: "no_applicable_tokens",
    });
  }

  console.log(
    JSON.stringify({
      level: "info",
      event_id: event.id,
      target_user_id: event.target_user_id,
      tokens: rows.length,
      sent: sentCount,
      skipped: skippedCount,
      failed: failedSendCount,
    }),
  );
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*" } });
  }

  try {
    const supabaseUrl = requireEnv("SUPABASE_URL");
    const serviceKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
    const onesignalAppId = requireEnv("ONESIGNAL_APP_ID");
    const onesignalRestKey = requireEnv("ONESIGNAL_REST_API_KEY");

    const supabase = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: claimed, error: claimErr } = await supabase.rpc(
      "claim_notification_events_batch",
      { p_batch_size: BATCH_SIZE },
    );

    if (claimErr) throw claimErr;

    const events = (claimed ?? []) as NotificationEvent[];
    if (events.length === 0) {
      return new Response(
        JSON.stringify({ ok: true, processed: 0, message: "no pending events" }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    for (const ev of events) {
      try {
        await processEvent(supabase, ev, onesignalAppId, onesignalRestKey);
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        await supabase
          .from("notification_events")
          .update({
            status: "failed",
            last_error: msg.slice(0, 2000),
            updated_at: new Date().toISOString(),
            processed_at: new Date().toISOString(),
          })
          .eq("id", ev.id);
        console.log(
          JSON.stringify({ level: "error", event_id: ev.id, error: msg }),
        );
      }
    }

    return new Response(
      JSON.stringify({ ok: true, processed: events.length }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.log(JSON.stringify({ level: "fatal", error: msg }));
    return new Response(JSON.stringify({ ok: false, error: msg }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
