;; Maintenance Scheduler Contract
;; Manages maintenance scheduling and cost allocation

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-TASK-NOT-FOUND (err u301))
(define-constant ERR-INVALID-INPUT (err u302))
(define-constant ERR-TASK-ALREADY-COMPLETED (err u303))
(define-constant ERR-INSUFFICIENT-FUNDS (err u304))

;; Data Variables
(define-data-var next-task-id uint u1)
(define-data-var total-tasks uint u0)
(define-data-var maintenance-fund uint u0)

;; Data Maps
(define-map maintenance-tasks
  { task-id: uint }
  {
    building-id: uint,
    task-type: (string-ascii 50),
    description: (string-ascii 200),
    priority: uint,
    estimated-cost: uint,
    actual-cost: uint,
    assigned-to: principal,
    created-by: principal,
    scheduled-date: uint,
    completion-date: uint,
    status: (string-ascii 20),
    requires-approval: bool
  }
)

(define-map maintenance-history
  { building-id: uint, task-type: (string-ascii 50) }
  {
    last-performed: uint,
    frequency: uint,
    total-cost: uint,
    task-count: uint,
    average-duration: uint
  }
)

(define-map cost-allocations
  { building-id: uint, period: uint }
  {
    total-allocated: uint,
    emergency-reserve: uint,
    routine-maintenance: uint,
    capital-improvements: uint,
    spent-amount: uint
  }
)

(define-map contractor-registry
  { contractor: principal }
  {
    name: (string-ascii 100),
    specialties: (string-ascii 200),
    rating: uint,
    completed-tasks: uint,
    is-approved: bool
  }
)

(define-map task-approvals
  { task-id: uint }
  {
    approved-by: principal,
    approval-date: uint,
    comments: (string-ascii 200)
  }
)

;; Authorization Functions
(define-public (register-contractor
  (contractor principal)
  (name (string-ascii 100))
  (specialties (string-ascii 200))
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)

    (map-set contractor-registry
      { contractor: contractor }
      {
        name: name,
        specialties: specialties,
        rating: u50,
        completed-tasks: u0,
        is-approved: true
      }
    )

    (ok true)
  )
)

(define-private (is-authorized-contractor (contractor principal))
  (default-to false (get is-approved (map-get? contractor-registry { contractor: contractor })))
)

;; Maintenance Task Functions
(define-public (create-maintenance-task
  (building-id uint)
  (task-type (string-ascii 50))
  (description (string-ascii 200))
  (priority uint)
  (estimated-cost uint)
  (scheduled-date uint)
  (requires-approval bool)
)
  (let
    (
      (task-id (var-get next-task-id))
    )
    (asserts! (> (len task-type) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (<= priority u5) ERR-INVALID-INPUT)
    (asserts! (>= scheduled-date block-height) ERR-INVALID-INPUT)

    (map-set maintenance-tasks
      { task-id: task-id }
      {
        building-id: building-id,
        task-type: task-type,
        description: description,
        priority: priority,
        estimated-cost: estimated-cost,
        actual-cost: u0,
        assigned-to: tx-sender,
        created-by: tx-sender,
        scheduled-date: scheduled-date,
        completion-date: u0,
        status: (if requires-approval "pending-approval" "scheduled"),
        requires-approval: requires-approval
      }
    )

    (var-set next-task-id (+ task-id u1))
    (var-set total-tasks (+ (var-get total-tasks) u1))

    (ok task-id)
  )
)

(define-public (assign-task (task-id uint) (contractor principal))
  (let
    (
      (task (unwrap! (map-get? maintenance-tasks { task-id: task-id }) ERR-TASK-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-authorized-contractor contractor) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq (get status task) "completed")) ERR-TASK-ALREADY-COMPLETED)

    (map-set maintenance-tasks
      { task-id: task-id }
      (merge task { assigned-to: contractor, status: "assigned" })
    )

    (ok true)
  )
)

(define-public (approve-task (task-id uint) (comments (string-ascii 200)))
  (let
    (
      (task (unwrap! (map-get? maintenance-tasks { task-id: task-id }) ERR-TASK-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (get requires-approval task) ERR-INVALID-INPUT)
    (asserts! (is-eq (get status task) "pending-approval") ERR-INVALID-INPUT)

    (map-set maintenance-tasks
      { task-id: task-id }
      (merge task { status: "approved" })
    )

    (map-set task-approvals
      { task-id: task-id }
      {
        approved-by: tx-sender,
        approval-date: block-height,
        comments: comments
      }
    )

    (ok true)
  )
)

(define-public (complete-task (task-id uint) (actual-cost uint))
  (let
    (
      (task (unwrap! (map-get? maintenance-tasks { task-id: task-id }) ERR-TASK-NOT-FOUND))
      (building-id (get building-id task))
      (task-type (get task-type task))
    )
    (asserts! (is-eq tx-sender (get assigned-to task)) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq (get status task) "completed")) ERR-TASK-ALREADY-COMPLETED)

    ;; Update task status
    (map-set maintenance-tasks
      { task-id: task-id }
      (merge task {
        status: "completed",
        actual-cost: actual-cost,
        completion-date: block-height
      })
    )

    ;; Update maintenance history
    (let
      (
        (history (default-to
                   { last-performed: u0, frequency: u0, total-cost: u0, task-count: u0, average-duration: u0 }
                   (map-get? maintenance-history { building-id: building-id, task-type: task-type })))
      )
      (map-set maintenance-history
        { building-id: building-id, task-type: task-type }
        {
          last-performed: block-height,
          frequency: (get frequency history),
          total-cost: (+ (get total-cost history) actual-cost),
          task-count: (+ (get task-count history) u1),
          average-duration: (/ (+ (* (get average-duration history) (get task-count history))
                                  (- block-height (get scheduled-date task)))
                               (+ (get task-count history) u1))
        }
      )
    )

    ;; Update contractor rating
    (let
      (
        (contractor-data (unwrap! (map-get? contractor-registry { contractor: tx-sender }) ERR-NOT-AUTHORIZED))
      )
      (map-set contractor-registry
        { contractor: tx-sender }
        (merge contractor-data { completed-tasks: (+ (get completed-tasks contractor-data) u1) })
      )
    )

    (ok true)
  )
)

(define-public (allocate-maintenance-budget
  (building-id uint)
  (period uint)
  (total-allocated uint)
  (emergency-reserve uint)
  (routine-maintenance uint)
  (capital-improvements uint)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq total-allocated (+ emergency-reserve routine-maintenance capital-improvements)) ERR-INVALID-INPUT)

    (map-set cost-allocations
      { building-id: building-id, period: period }
      {
        total-allocated: total-allocated,
        emergency-reserve: emergency-reserve,
        routine-maintenance: routine-maintenance,
        capital-improvements: capital-improvements,
        spent-amount: u0
      }
    )

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-maintenance-task (task-id uint))
  (map-get? maintenance-tasks { task-id: task-id })
)

(define-read-only (get-maintenance-history (building-id uint) (task-type (string-ascii 50)))
  (map-get? maintenance-history { building-id: building-id, task-type: task-type })
)

(define-read-only (get-cost-allocation (building-id uint) (period uint))
  (map-get? cost-allocations { building-id: building-id, period: period })
)

(define-read-only (get-contractor-info (contractor principal))
  (map-get? contractor-registry { contractor: contractor })
)

(define-read-only (get-task-approval (task-id uint))
  (map-get? task-approvals { task-id: task-id })
)

(define-read-only (get-total-tasks)
  (var-get total-tasks)
)

(define-read-only (calculate-next-maintenance (building-id uint) (task-type (string-ascii 50)))
  (let
    (
      (history (map-get? maintenance-history { building-id: building-id, task-type: task-type }))
    )
    (match history
      history-data (+ (get last-performed history-data) (get frequency history-data))
      u0
    )
  )
)
