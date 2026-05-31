import {StartupDocument, StartupListItem} from "../types";
import {db} from "../shared/firebase";

const startupsCollection = db.collection("startups");

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
  const snapshot = await startupsCollection
    .where("isActive", "==", true)
    .limit(100)
    .get();

  return snapshot.docs.map((doc) => {
    const data = doc.data() as StartupDocument;
    return toStartupListItem(doc.id, data);
  });
}
