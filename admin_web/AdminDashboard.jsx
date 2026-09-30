// Interface administrateur — application web séparée (React + Firebase SDK web).
// Ce fichier est un point de départ fonctionnel pour le tableau de bord :
// - validation des pharmacies en attente
// - vue d'ensemble du stock de la ville par médicament/commune
// - gestion du prix d'abonnement (collection "config")
//
// À placer dans un projet React (Vite ou Create React App) avec
// firebase/firestore installé et configuré (firebaseConfig).

import { useEffect, useState } from "react";
import {
  collection,
  query,
  where,
  onSnapshot,
  doc,
  updateDoc,
  getDocs,
  setDoc,
} from "firebase/firestore";
import { db } from "./firebaseConfig"; // à créer : initializeApp + getFirestore

export default function AdminDashboard() {
  const [pendingPharmacies, setPendingPharmacies] = useState([]);
  const [stats, setStats] = useState({ active: 0, pending: 0, suspended: 0 });
  const [shortageByMedicine, setShortageByMedicine] = useState([]);
  const [price, setPrice] = useState(0);

  // ---------- Demandes de pharmacies en attente ----------
  useEffect(() => {
    const q = query(
      collection(db, "pharmacies"),
      where("registrationStatus", "==", "pending")
    );
    const unsub = onSnapshot(q, (snap) => {
      setPendingPharmacies(
        snap.docs.map((d) => ({ id: d.id, ...d.data() }))
      );
    });
    return unsub;
  }, []);

  // ---------- Statistiques globales ----------
  useEffect(() => {
    const unsub = onSnapshot(collection(db, "pharmacies"), (snap) => {
      let active = 0, pending = 0, suspended = 0;
      snap.forEach((d) => {
        const status = d.data().registrationStatus;
        const payment = d.data().paymentStatus;
        if (status === "pending") pending++;
        else if (payment === "suspended") suspended++;
        else if (status === "validated") active++;
      });
      setStats({ active, pending, suspended });
    });
    return unsub;
  }, []);

  // ---------- Vue "pénuries par médicament" ----------
  // Agrège, pour chaque médicament, le nombre de pharmacies en rupture
  // vs disponible. Pour un vrai volume de données, ceci devrait être
  // pré-calculé côté serveur (Cloud Function planifiée) plutôt que
  // recalculé à la volée dans le navigateur.
  const loadShortageReport = async () => {
    const stockSnap = await getDocs(collection(db, "stock"));
    const medicinesSnap = await getDocs(collection(db, "medicines"));

    const medicineNames = {};
    medicinesSnap.forEach((d) => (medicineNames[d.id] = d.data().genericName));

    const counts = {};
    stockSnap.forEach((d) => {
      const { medicineId, status } = d.data();
      if (!counts[medicineId]) {
        counts[medicineId] = { available: 0, outOfStock: 0 };
      }
      counts[medicineId][status === "available" ? "available" : "outOfStock"]++;
    });

    const report = Object.entries(counts).map(([medicineId, c]) => ({
      medicineId,
      name: medicineNames[medicineId] || medicineId,
      available: c.available,
      outOfStock: c.outOfStock,
      shortageRatio: c.outOfStock / (c.available + c.outOfStock || 1),
    }));

    report.sort((a, b) => b.shortageRatio - a.shortageRatio);
    setShortageByMedicine(report);
  };

  useEffect(() => {
    loadShortageReport();
  }, []);

  // ---------- Validation / refus d'une pharmacie ----------
  const validatePharmacy = async (id) => {
    await updateDoc(doc(db, "pharmacies", id), {
      registrationStatus: "validated",
      active: true,
      freeTrialStartDate: new Date(),
      paymentStatus: "freeTrial",
    });
  };

  const rejectPharmacy = async (id) => {
    await updateDoc(doc(db, "pharmacies", id), {
      registrationStatus: "rejected",
      active: false,
    });
  };

  // ---------- Configuration du prix ----------
  const savePrice = async () => {
    await setDoc(doc(db, "config", "global"), {
      monthlySubscriptionPrice: Number(price),
    }, { merge: true });
  };

  return (
    <div style={{ padding: 24, fontFamily: "sans-serif" }}>
      <h1>Tableau de bord — Pharma Kin</h1>

      <section style={{ display: "flex", gap: 16, marginBottom: 32 }}>
        <StatCard label="Pharmacies actives" value={stats.active} />
        <StatCard label="En attente de validation" value={stats.pending} />
        <StatCard label="Suspendues (impayées)" value={stats.suspended} />
      </section>

      <section style={{ marginBottom: 32 }}>
        <h2>Demandes en attente</h2>
        {pendingPharmacies.length === 0 && <p>Aucune demande en attente.</p>}
        <ul>
          {pendingPharmacies.map((p) => (
            <li key={p.id} style={{ marginBottom: 8 }}>
              <strong>{p.name}</strong> — {p.commune} — {p.phone}
              <button onClick={() => validatePharmacy(p.id)} style={{ marginLeft: 12 }}>
                Valider
              </button>
              <button onClick={() => rejectPharmacy(p.id)} style={{ marginLeft: 8 }}>
                Refuser
              </button>
            </li>
          ))}
        </ul>
      </section>

      <section style={{ marginBottom: 32 }}>
        <h2>Pénuries par médicament (ville entière)</h2>
        <table>
          <thead>
            <tr>
              <th>Médicament</th>
              <th>Disponible</th>
              <th>En rupture</th>
              <th>% de rupture</th>
            </tr>
          </thead>
          <tbody>
            {shortageByMedicine.map((r) => (
              <tr key={r.medicineId}>
                <td>{r.name}</td>
                <td>{r.available}</td>
                <td>{r.outOfStock}</td>
                <td>{Math.round(r.shortageRatio * 100)}%</td>
              </tr>
            ))}
          </tbody>
        </table>
        {/* Note : une vraie heatmap par commune nécessite de croiser ces
            données avec la commune de chaque pharmacie. À faire une fois
            le volume de données réel disponible pour choisir la bonne
            librairie de visualisation (ex: react-simple-maps). */}
      </section>

      <section>
        <h2>Prix de l'abonnement mensuel</h2>
        <input
          type="number"
          value={price}
          onChange={(e) => setPrice(e.target.value)}
          placeholder="Prix en USD"
        />
        <button onClick={savePrice} style={{ marginLeft: 8 }}>
          Enregistrer
        </button>
      </section>
    </div>
  );
}

function StatCard({ label, value }) {
  return (
    <div style={{ border: "1px solid #ddd", borderRadius: 8, padding: 16, minWidth: 160 }}>
      <div style={{ fontSize: 28, fontWeight: "bold" }}>{value}</div>
      <div style={{ color: "#666" }}>{label}</div>
    </div>
  );
}
