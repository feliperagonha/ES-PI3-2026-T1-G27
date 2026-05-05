import { setGlobalOptions } from "firebase-functions/v2/options";

setGlobalOptions({ maxInstances: 10 });

// exporta todos os módulos
export * from "./authentication";
//export * from "./startups";
export * from "./exchange";
export * from "./wallet";
//export * from "./transactions";
//export * from "./questions";
//export * from "./dashboard";
//export * from "./notifications";
//export * from "./users";