import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

admin.initializeApp();
const db = admin.firestore();

// ─────────────────────────────────────────────────────────────────────────────
// STUB: onNewBooking
// Triggered when a user books a coach session.
// TODO: Integrate real payment gateway (Stripe, etc.) before going live.
// ─────────────────────────────────────────────────────────────────────────────
export const onNewBooking = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snap, context) => {
    const booking = snap.data();
    const { userId, coachId, coachName, slot } = booking;

    functions.logger.info("New booking created", {
      bookingId: context.params.bookingId,
      userId,
      coachId,
    });

    // Notify the coach
    await _sendNotification(coachId, {
      title: "New Session Booked!",
      body: `A user has booked a session with you at ${slot}.`,
      type: "new_booking",
      bookingId: context.params.bookingId,
    });

    // Notify the user with confirmation
    await _sendNotification(userId, {
      title: "Session Confirmed!",
      body: `Your session with ${coachName} at ${slot} is confirmed.`,
      type: "booking_confirmed",
      bookingId: context.params.bookingId,
    });
  });

// ─────────────────────────────────────────────────────────────────────────────
// STUB: onBookingStatusChange
// Triggered when a booking status is updated (e.g., cancelled, completed).
// ─────────────────────────────────────────────────────────────────────────────
export const onBookingStatusChange = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) return null;

    functions.logger.info("Booking status changed", {
      bookingId: context.params.bookingId,
      from: before.status,
      to: after.status,
    });

    const { userId, coachId, coachName, slot } = after;

    if (after.status === "cancelled") {
      await _sendNotification(coachId, {
        title: "Session Cancelled",
        body: `A session at ${slot} has been cancelled by the user.`,
        type: "booking_cancelled",
        bookingId: context.params.bookingId,
      });
      await _sendNotification(userId, {
        title: "Session Cancelled",
        body: `Your session with ${coachName} at ${slot} has been cancelled.`,
        type: "booking_cancelled",
        bookingId: context.params.bookingId,
      });
    }

    if (after.status === "completed") {
      // Award XP to user for completing a session
      await db.collection("users").doc(userId).update({
        xp: admin.firestore.FieldValue.increment(200),
      });

      await _sendNotification(userId, {
        title: "Session Completed! +200 XP",
        body: `Great work! Your session with ${coachName} is done. You earned 200 XP!`,
        type: "session_completed",
        bookingId: context.params.bookingId,
      });
    }

    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// STUB: onSubscriptionChange
// Triggered when a user's subscription document is created or updated.
// TODO: Validate payment receipt server-side before granting premium.
// ─────────────────────────────────────────────────────────────────────────────
export const onSubscriptionChange = functions.firestore
  .document("subscriptions/{userId}")
  .onWrite(async (change, context) => {
    const userId = context.params.userId;
    const data = change.after.exists ? change.after.data() : null;

    if (!data) return null;

    const tier = data.tier as string;
    const isPremium = tier !== "free";

    functions.logger.info("Subscription updated", { userId, tier });

    await db.collection("users").doc(userId).update({
      isPremium,
      subscriptionTier: tier,
    });

    if (isPremium) {
      await _sendNotification(userId, {
        title: `Welcome to ${data.plan}!`,
        body: "Your premium subscription is now active. Enjoy all features!",
        type: "subscription_activated",
        tier,
      });
    }

    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// STUB: onNewUser
// Triggered when a new user document is created in Firestore.
// Seeds default data and sends a welcome notification.
// ─────────────────────────────────────────────────────────────────────────────
export const onNewUser = functions.firestore
  .document("users/{userId}")
  .onCreate(async (snap, context) => {
    const user = snap.data();
    const userId = context.params.userId;

    functions.logger.info("New user created", { userId, role: user.role });

    // Create default subscription (free tier)
    await db.collection("subscriptions").doc(userId).set({
      userId,
      tier: "free",
      plan: "Free",
      status: "active",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send welcome notification
    await _sendNotification(userId, {
      title: `Welcome to BetterYou, ${user.name?.split(" ")[0] ?? "there"}!`,
      body: "Start your health journey today. Complete your profile to earn your first XP!",
      type: "welcome",
    });

    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// onFcmQueueCreate
// Consumes documents written to /fcm_queue by the Flutter app via
// FCMService.sendNotificationToUser() and dispatches them as real FCM pushes.
// Also writes an in-app notification doc so the bell icon updates.
// ─────────────────────────────────────────────────────────────────────────────
export const onFcmQueueCreate = functions.firestore
  .document("fcm_queue/{queueId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const {
      toUserId,
      fromUserId,
      fromUserName,
      type,
      title,
      body,
      data: payload,
    } = data;

    if (!toUserId || !title) {
      await snap.ref.update({ status: "invalid", processedAt: admin.firestore.FieldValue.serverTimestamp() });
      return null;
    }

    try {
      // 1. Always write an in-app notification doc so the user sees it in the bell
      await _sendNotification(toUserId, {
        title,
        body: body ?? "",
        type: type ?? "general",
        fromUserId: fromUserId ?? null,
        fromUserName: fromUserName ?? null,
        ...(payload ?? {}),
      });

      // 2. Look up the recipient's FCM token
      const userDoc = await db.collection("users").doc(toUserId).get();
      const fcmToken = userDoc.data()?.fcmToken as string | undefined;

      if (!fcmToken) {
        await snap.ref.update({
          status: "no_token",
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        functions.logger.info("No FCM token for user, skipped push", { toUserId });
        return null;
      }

      // 3. Send the FCM push
      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body: body ?? "" },
        data: {
          type: type ?? "general",
          fromUserId: fromUserId ?? "",
          fromUserName: fromUserName ?? "",
          ...Object.fromEntries(
            Object.entries(payload ?? {}).map(([k, v]) => [k, String(v)]),
          ),
        },
        android: {
          priority: "high",
          notification: {
            channelId: type ?? "general",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: { sound: "default", badge: 1 },
          },
        },
      });

      await snap.ref.update({
        status: "sent",
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      functions.logger.info("FCM push delivered", { toUserId, type });
    } catch (err) {
      functions.logger.error("FCM dispatch failed", err);
      await snap.ref.update({
        status: "failed",
        error: String(err),
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// dailyStreakCheck (Scheduled Function)
// Runs every day at midnight UTC. Resets the streak of users who didn't log
// anything yesterday.
// ─────────────────────────────────────────────────────────────────────────────
export const dailyStreakCheck = functions.pubsub
  .schedule("0 0 * * *")
  .timeZone("UTC")
  .onRun(async () => {
    functions.logger.info("Running daily streak check...");
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);

    const usersSnap = await db.collection("users")
      .where("currentStreak", ">", 0)
      .get();

    const batch = db.batch();
    let resetCount = 0;
    usersSnap.forEach((doc) => {
      const lastLog = doc.data().lastLogDate?.toDate();
      if (!lastLog || lastLog < yesterday) {
        batch.update(doc.ref, { currentStreak: 0 });
        resetCount++;
      }
    });

    if (resetCount > 0) await batch.commit();
    functions.logger.info(`Streak check complete. Reset ${resetCount} streaks.`);
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// cleanupOldNotifications (Scheduled Function)
// Runs weekly; deletes notifications and processed FCM queue entries older
// than 30 days.
// ─────────────────────────────────────────────────────────────────────────────
export const cleanupOldNotifications = functions.pubsub
  .schedule("0 2 * * 0")
  .timeZone("UTC")
  .onRun(async () => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 30);

    const collections = ["notifications", "fcm_queue"];
    let totalDeleted = 0;

    for (const col of collections) {
      const snap = await db.collection(col)
        .where("createdAt", "<", cutoff)
        .limit(500)
        .get();
      const batch = db.batch();
      snap.forEach((doc) => batch.delete(doc.ref));
      if (!snap.empty) await batch.commit();
      totalDeleted += snap.size;
    }

    functions.logger.info(`Deleted ${totalDeleted} old documents.`);
    return null;
  });

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Write an in-app notification document
// ─────────────────────────────────────────────────────────────────────────────
async function _sendNotification(
  toUserId: string,
  payload: Record<string, unknown>
): Promise<void> {
  await db.collection("notifications").add({
    toUserId,
    ...payload,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
