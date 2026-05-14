//Juliano Perusso
//RA: 24023434

import {setGlobalOptions} from "firebase-functions/v2/options";

setGlobalOptions({maxInstances: 10});

export * from "./authentication";
export * from "./exchange";
export * from "./wallet";
export * from "./profile";
export * from "./startups";
