const admin = require("firebase-admin");
const fs = require("fs");
const { parse } = require("csv-parse/sync");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

console.log("SCRIPT INICIADO");

const csv = fs.readFileSync("./Startups.csv", "utf8");
console.log("CSV lido com sucesso");

const records = parse(csv, {
  columns: true,
  skip_empty_lines: true,
  delimiter: ",",
  trim: true
});

console.log("Quantidade de registros encontrados:", records.length);

function splitList(str) {
  if (!str) return [];
  return String(str)
    .split(";")
    .map((s) => s.trim())
    .filter(Boolean);
}

function parsePercent(str) {
  if (!str) return 0;
  return Number(String(str).replace("%", "").trim()) || 0;
}

async function importar() {
  try {
    for (const row of records) {
      console.log("Linha lida:", row);

      const socios = splitList(row.socios);
      const participacoes = splitList(row.participacao_societaria);

      const founders = socios.map((nome, i) => ({
        name: nome,
        participation: parsePercent(participacoes[i]),
      }));

      const doc = {
        name: row.nome_startup || "",
        description: row.descricao || "",
        stage: (row.estagio || "").toLowerCase(),
        sector: (row.setor || "").toLowerCase(),
        capitalInvested: Number(row.capital_aportado) || 0,
        totalTokens: Number(row.tokens_emitidos) || 0,
        tokensAvailable: Number(row.tokens_emitidos) || 0,
        initialPrice: 10,
        currentPrice: 10,
        totalInvested: 0,
        status: row.status || "",
        isActive: (row.status || "").toLowerCase() === "ativa",
        founders: founders,
        mentors: splitList(row.mentores_conselho),
        videoDemo: row.video_demo || "",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      };

      const docId = `startup_${Number(row.id_startup)}`;

      await db.collection("startups").doc(docId).set(doc, { merge: true });

      console.log("Importado:", docId, "-", doc.name);
    }

    console.log("\n FINALIZADO COM SUCESSO");
  } catch (erro) {
    console.error(" Erro:", erro);
  }
}

importar();