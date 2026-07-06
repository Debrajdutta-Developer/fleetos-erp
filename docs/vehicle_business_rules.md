# FleetOS ERP - Vehicle Module Business Rules Specification

This document defines the core business logic, compliance constraints, and operational rules governing the **Vehicle Module** within FleetOS ERP. These rules must be enforced across all client interfaces, backend databases, and automation services to ensure compliance and cost-effective operations.

---

## 🔄 1. Vehicle Lifecycle State Machine

A vehicle’s status determines its eligibility for driver assignments, trip dispatches, maintenance logging, and financial calculations. The transition between these states must follow the strict rules below.

```
       [ Registration ]
              │
              ▼
    ┌──►  [ Active ]  ◄──┐
    │         │          │
    │         ▼          │
    │   [ Maintenance ]  │
    │         │          │
    │         ▼          │
    └───  [ Idle ]  ─────┘
              │
              ▼
           [ Sold ]
              │
              ▼
         [ Archived ]
```

### 1.1 State Definitions & Transition Criteria

#### 1.  **Registration (Onboarding Phase)**
*   **Definition:** The vehicle record has been initialized (VIN, make, model, purchase specs captured) but is not yet road-ready.
*   **Operational Rules:**
    *   Cannot be assigned to any drivers or trips.
    *   GPS/Telematics hardware pairing occurs in this state.
*   **Transition out:** Moves to **Active** only after a verified safety inspection certificate is uploaded and active insurance details are verified.

#### 2.  **Active (Operational)**
*   **Definition:** The vehicle is road-ready, fully compliant, and available for operations.
*   **Operational Rules:**
    *   Telemetry feeds (GPS, OBD-II/CAN-bus data) must be polled.
    *   Eligible for driver and trip assignments.
*   **Transition out:** Moves to **Maintenance** automatically if a fault code is raised or manually by dispatch. Moves to **Idle** if unassigned for >48 hours.

#### 3.  **Maintenance (Out of Service)**
*   **Definition:** Undergoing scheduled servicing or unscheduled breakdown repairs.
*   **Operational Rules:**
    *   Locked from all trip dispatches.
    *   Current driver assignments are automatically unlinked.
*   **Transition out:** Moves to **Active** (or **Idle**) only when a maintenance work order is marked "Closed" and signed off by a certified technician.

#### 4.  **Idle (Inactive Asset)**
*   **Definition:** Fully operational but currently has no active trip assignments or driver links.
*   **Operational Rules:**
    *   Telemetry checks are reduced to once per day (battery saver mode).
    *   Flagged on the operator console for under-utilization alerts.
*   **Transition out:** Moves to **Active** automatically upon assignment to a driver or dispatch trip.

#### 5.  **Sold (Decommissioned)**
*   **Definition:** Liquidated or removed from the tenant's corporate asset sheet.
*   **Operational Rules:**
    *   Permanently read-only.
    *   Telemetry links are severed.
    *   Unlinked from all historic driver mappings.
*   **Transition out:** Terminal state. Can only move to **Archived**.

#### 6.  **Archived (Soft Deleted)**
*   **Definition:** Retained solely for historical tax audits, mileage reviews, and insurance reviews.
*   **Operational Rules:**
    *   Hidden from all search grids and active drop-downs.
    *   Cannot transition back to any active lifecycle state.

---

## 👤 2. Driver Assignment Rules

To minimize liability and coordinate driver shifts, the system enforces the following constraints:

1.  **The Single Occupancy Rule:** A vehicle can have a maximum of **one** active primary driver linked at any given timestamp. Secondary drivers (co-drivers) must be explicitly registered under a separate "Co-Driver" role on the Trip Manifest.
2.  **License Category Enforcement:** The assigned driver's Commercial Driver's License (CDL) class must match or exceed the Gross Vehicle Weight Rating (GVWR) of the vehicle:
    *   *Class A CDL:* Required for tractor-trailers (GVWR > 26,000 lbs, towing > 10,000 lbs).
    *   *Class B CDL:* Required for straight trucks or box trucks (GVWR > 26,000 lbs, towing < 10,000 lbs).
3.  **Safety Score Gate:** Drivers with a safety rating score below **70%** (calculated from telemetry indicators of hard braking, speeding, and rapid acceleration) are blocked from operating heavy-duty or high-value vehicles (Class A).
4.  **Assigned Status Logic:** A driver must be in the `available` state to be linked. Once assigned, their status transitions to `on_duty` and they cannot be linked to another vehicle.

---

## 🗺️ 3. Trip Assignment Rules

To maximize payload efficiency and preserve safety margins, trips are dispatched using these parameters:

1.  **State Gate:** The vehicle must be in an **Active** lifecycle state. Vehicles in `Maintenance` or `Sold` states cannot be selected during trip planning.
2.  **Payload Compliance Margin:** The cargo weight specified in the trip manifest must not exceed **90%** of the vehicle's maximum legal payload capacity. A 10% safety margin is enforced to prevent premature suspension wear and compliance issues.
3.  **Range / State-of-Charge Validation:**
    *   *Internal Combustion Engines (ICE):* The current fuel volume (reported via CAN-bus telemetry) must be sufficient to complete the route or reach the first planned refuel station.
    *   *Electric Vehicles (EV):* State of Charge (SoC) must exceed the calculated energy demand for the route (incorporating elevation gains and payload weight) plus a **15% battery safety reserve**.
4.  **No Schedule Overlap:** A vehicle cannot be assigned to multiple trips with overlapping delivery windows. A minimum **2-hour turnaround buffer** is enforced between the estimated completion time of Trip A and the departure time of Trip B.

---

## 📄 4. Insurance & Compliance Expiry Rules

Regulatory compliance requires active insurance coverage. FleetOS ERP enforces these automated checkpoints:

1.  **Proactive Notifications:** The system monitors policy expiration dates and triggers alerts:
    *   *Warning 1 (30 days prior):* Sends email notification to the Fleet Manager.
    *   *Warning 2 (15 days prior):* Sends FCM push notification to the manager console.
    *   *Warning 3 (7 days prior):* Displays red compliance badge on the vehicle dashboard widget.
2.  **Automated Compliance Lockout:** 
    *   If the system time passes the policy expiration date and no verified policy update is recorded, the vehicle’s state is automatically transitioned to **Maintenance** with a sub-state tag: `Compliance Lock`.
3.  **Dispatch Block:**
    *   Any vehicle under a `Compliance Lock` is blocked from trip dispatches.
    *   Active trips scheduled to complete *after* the expiration date cannot be initialized.
4.  **Re-activation Criteria:** The vehicle can return to `Active` status only after a new insurance certificate is uploaded (Firebase Storage) and verified by a manager, updating the policy details and pushing the expiration date into the future.
