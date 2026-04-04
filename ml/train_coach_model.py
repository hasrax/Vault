import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report
import joblib
import coremltools as ct

np.random.seed(42)


def synth_row():
    needs_util = np.clip(np.random.normal(0.8, 0.25), 0, 2)
    wants_util = np.clip(np.random.normal(0.7, 0.3), 0, 2)
    savings_util = np.clip(np.random.normal(0.4, 0.3), 0, 2)
    savings_progress = np.clip(np.random.normal(0.5, 0.3), 0, 1)
    net_balance_ratio = np.clip(np.random.normal(0.2, 0.5), -1, 2)
    income_expense_ratio = np.clip(np.random.normal(1.0, 0.5), 0, 3)
    upcoming_bills_count = np.random.randint(0, 6)
    upcoming_shifts_count = np.random.randint(0, 6)
    return {
        "needs_util": needs_util,
        "wants_util": wants_util,
        "savings_util": savings_util,
        "savings_progress": savings_progress,
        "net_balance_ratio": net_balance_ratio,
        "income_expense_ratio": income_expense_ratio,
        "upcoming_bills_count": upcoming_bills_count,
        "upcoming_shifts_count": upcoming_shifts_count,
    }


def label_tip(r):
    if r["needs_util"] > 1.0:
        return "needs_over"
    if r["wants_util"] > 1.0:
        return "reduce_wants"
    if r["savings_progress"] < 0.3 and r["savings_util"] < 0.3:
        return "savings_low"
    if r["upcoming_bills_count"] >= 3 and r["net_balance_ratio"] < 0.2:
        return "upcoming_bills"
    if r["upcoming_shifts_count"] >= 2 and r["income_expense_ratio"] < 1.0:
        return "shift_income_tip"
    return "good_progress"


rows = [synth_row() for _ in range(5000)]
df = pd.DataFrame(rows)
df["label"] = df.apply(label_tip, axis=1)

X = df.drop(columns=["label"])
y = df["label"]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, stratify=y
)
model = RandomForestClassifier(n_estimators=200, random_state=42)
model.fit(X_train, y_train)

print(classification_report(y_test, model.predict(X_test)))

joblib.dump(model, "coach_model.joblib")

mlmodel = ct.converters.sklearn.convert(
    model,
    input_features=[(c, ct.models.datatypes.Double()) for c in X.columns],
    output_feature_names=["label"],
)
mlmodel.save("CoachModel.mlmodel")
print("Saved CoachModel.mlmodel")
