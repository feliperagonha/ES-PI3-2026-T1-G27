import {StartupDocument, StartupListItem} from "../types";
import {db} from "../shared/firebase";
import {
  buildExpiredTokenResetUpdate,
  buildPendingSoldOutMarkerUpdate,
  evaluateStartupTokenReset,
} from "../../shared/startupTokenReset";

const startupsCollection = db.collection("startups");

async function applyExpiredStartupTokenResets(): Promise<void> {
  const now = new Date();
  const snapshot = await startupsCollection
    .where("tokensAvailable", "==", 0)
    .limit(100)
    .get();

  if (snapshot.empty) {
    return;
  }

  const batch = db.batch();
  let updates = 0;

  for (const doc of snapshot.docs) {
    const evaluation = evaluateStartupTokenReset(doc.data(), now);

    if (evaluation.shouldReset) {
      batch.update(doc.ref, buildExpiredTokenResetUpdate(evaluation));
      updates++;
      continue;
    }

    if (evaluation.shouldMarkSoldOut) {
      batch.update(doc.ref, buildPendingSoldOutMarkerUpdate(evaluation));
      updates++;
    }
  }

  if (updates > 0) {
    await batch.commit();
  }
}

function toStartupListItem(
  id: string,
  startup: StartupDocument
): StartupListItem {
  return {
    id,
    name: startup.name,
    description: startup.description,
    stage: startup.stage,
    sector: startup.sector,
    capitalInvested: startup.capitalInvested,
    totalTokens: startup.totalTokens,
    tokensAvailable: startup.tokensAvailable,
    initialPrice: startup.initialPrice,
    currentPrice: startup.currentPrice,
    totalInvested: startup.totalInvested,
    status: startup.status,
    isActive: startup.isActive,
    founders: startup.founders ?? [],
    mentors: startup.mentors ?? [],
    videoDemo: startup.videoDemo,
  };
}

export async function listStartupItems(): Promise<StartupListItem[]> {
  await applyExpiredStartupTokenResets();

  const snapshot = await startupsCollection
    .where("isActive", "==", true)
    .limit(100)
    .get();

  return snapshot.docs.map((doc) => {
    const data = doc.data() as StartupDocument;
    return toStartupListItem(doc.id, data);
  });
}
