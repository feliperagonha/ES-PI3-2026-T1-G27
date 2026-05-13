import {HttpsError, onCall} from "firebase-functions/v2/https";
import {listStartupItems} from "../repositories/startupRepository";
import {validateListStartupsData} from "../shared/validation";
import {ListStartupsResponse} from "../types";

export const listStartups = onCall(
  {region: "southamerica-east1"},
  async (request): Promise<ListStartupsResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para acessar o catálogo.");
    }

    const {stage, search} = validateListStartupsData(request.data);

    let startups = await listStartupItems();

    if (stage) {
      startups = startups.filter((startup) =>
        startup.stage.toLowerCase() === stage
      );
    }

    if (search) {
      startups = startups.filter((startup) => {
        const searchable = [
          startup.name,
          startup.description,
          startup.stage,
          startup.sector,
          startup.status,
        ]
          .join(" ")
          .toLowerCase();

        return searchable.includes(search);
      });
    }

    startups.sort((a, b) => a.name.localeCompare(b.name, "pt-BR"));

    return {
      success: true,
      count: startups.length,
      data: startups,
    };
  }
);