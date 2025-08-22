;; Building Performance Monitoring Contract
;; Tracks building performance and energy optimization

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-BUILDING-NOT-FOUND (err u201))
(define-constant ERR-INVALID-INPUT (err u202))
(define-constant ERR-INSUFFICIENT-DATA (err u203))

;; Data Variables
(define-data-var next-building-id uint u1)
(define-data-var total-buildings uint u0)

;; Data Maps
(define-map buildings
  { building-id: uint }
  {
    name: (string-ascii 100),
    address: (string-ascii 200),
    total-area: uint,
    floors: uint,
    building-type: (string-ascii 50),
    construction-year: uint,
    energy-rating: (string-ascii 10),
    manager: principal,
    is-active: bool
  }
)

(define-map energy-metrics
  { building-id: uint, period: uint }
  {
    electricity-consumption: uint,
    gas-consumption: uint,
    water-consumption: uint,
    renewable-generation: uint,
    efficiency-score: uint,
    cost-per-sqft: uint,
    recorded-at: uint
  }
)

(define-map environmental-data
  { building-id: uint, timestamp: uint }
  {
    temperature: uint,
    humidity: uint,
    air-quality: uint,
    co2-level: uint,
    light-level: uint,
    noise-level: uint
  }
)

(define-map performance-targets
  { building-id: uint }
  {
    target-efficiency: uint,
    max-energy-consumption: uint,
    min-air-quality: uint,
    target-temperature: uint,
    max-co2-level: uint
  }
)

(define-map authorized-managers
  { manager: principal }
  { is-authorized: bool, buildings-managed: uint }
)

;; Authorization Functions
(define-public (authorize-manager (manager principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-managers { manager: manager } { is-authorized: true, buildings-managed: u0 }))
  )
)

(define-private (is-authorized-for-building (building-id uint) (caller principal))
  (let
    (
      (building (map-get? buildings { building-id: building-id }))
    )
    (match building
      building-data (or
                      (is-eq caller CONTRACT-OWNER)
                      (is-eq caller (get manager building-data))
                      (default-to false (get is-authorized (map-get? authorized-managers { manager: caller }))))
      false
    )
  )
)

;; Building Management Functions
(define-public (register-building
  (name (string-ascii 100))
  (address (string-ascii 200))
  (total-area uint)
  (floors uint)
  (building-type (string-ascii 50))
  (construction-year uint)
)
  (let
    (
      (building-id (var-get next-building-id))
    )
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER)
                  (default-to false (get is-authorized (map-get? authorized-managers { manager: tx-sender }))))
              ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> total-area u0) ERR-INVALID-INPUT)
    (asserts! (> floors u0) ERR-INVALID-INPUT)

    (map-set buildings
      { building-id: building-id }
      {
        name: name,
        address: address,
        total-area: total-area,
        floors: floors,
        building-type: building-type,
        construction-year: construction-year,
        energy-rating: "pending",
        manager: tx-sender,
        is-active: true
      }
    )

    (var-set next-building-id (+ building-id u1))
    (var-set total-buildings (+ (var-get total-buildings) u1))

    (ok building-id)
  )
)

(define-public (record-energy-metrics
  (building-id uint)
  (period uint)
  (electricity-consumption uint)
  (gas-consumption uint)
  (water-consumption uint)
  (renewable-generation uint)
)
  (let
    (
      (building (unwrap! (map-get? buildings { building-id: building-id }) ERR-BUILDING-NOT-FOUND))
      (total-consumption (+ electricity-consumption gas-consumption))
      (efficiency-score (if (> total-consumption u0)
                          (/ (* renewable-generation u100) total-consumption)
                          u0))
      (cost-per-sqft (if (> (get total-area building) u0)
                       (/ total-consumption (get total-area building))
                       u0))
    )
    (asserts! (is-authorized-for-building building-id tx-sender) ERR-NOT-AUTHORIZED)

    (map-set energy-metrics
      { building-id: building-id, period: period }
      {
        electricity-consumption: electricity-consumption,
        gas-consumption: gas-consumption,
        water-consumption: water-consumption,
        renewable-generation: renewable-generation,
        efficiency-score: efficiency-score,
        cost-per-sqft: cost-per-sqft,
        recorded-at: block-height
      }
    )

    (ok efficiency-score)
  )
)

(define-public (record-environmental-data
  (building-id uint)
  (temperature uint)
  (humidity uint)
  (air-quality uint)
  (co2-level uint)
  (light-level uint)
  (noise-level uint)
)
  (begin
    (asserts! (is-some (map-get? buildings { building-id: building-id })) ERR-BUILDING-NOT-FOUND)
    (asserts! (is-authorized-for-building building-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= humidity u100) ERR-INVALID-INPUT)
    (asserts! (<= air-quality u500) ERR-INVALID-INPUT)

    (map-set environmental-data
      { building-id: building-id, timestamp: block-height }
      {
        temperature: temperature,
        humidity: humidity,
        air-quality: air-quality,
        co2-level: co2-level,
        light-level: light-level,
        noise-level: noise-level
      }
    )

    (ok true)
  )
)

(define-public (set-performance-targets
  (building-id uint)
  (target-efficiency uint)
  (max-energy-consumption uint)
  (min-air-quality uint)
  (target-temperature uint)
  (max-co2-level uint)
)
  (begin
    (asserts! (is-some (map-get? buildings { building-id: building-id })) ERR-BUILDING-NOT-FOUND)
    (asserts! (is-authorized-for-building building-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= target-efficiency u100) ERR-INVALID-INPUT)

    (map-set performance-targets
      { building-id: building-id }
      {
        target-efficiency: target-efficiency,
        max-energy-consumption: max-energy-consumption,
        min-air-quality: min-air-quality,
        target-temperature: target-temperature,
        max-co2-level: max-co2-level
      }
    )

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-building (building-id uint))
  (map-get? buildings { building-id: building-id })
)

(define-read-only (get-energy-metrics (building-id uint) (period uint))
  (map-get? energy-metrics { building-id: building-id, period: period })
)

(define-read-only (get-environmental-data (building-id uint) (timestamp uint))
  (map-get? environmental-data { building-id: building-id, timestamp: timestamp })
)

(define-read-only (get-performance-targets (building-id uint))
  (map-get? performance-targets { building-id: building-id })
)

(define-read-only (get-total-buildings)
  (var-get total-buildings)
)

(define-read-only (calculate-efficiency-rating (building-id uint) (period uint))
  (let
    (
      (metrics (map-get? energy-metrics { building-id: building-id, period: period }))
      (targets (map-get? performance-targets { building-id: building-id }))
    )
    (match metrics
      metric-data (match targets
                    target-data (let
                                  (
                                    (efficiency (get efficiency-score metric-data))
                                    (target (get target-efficiency target-data))
                                  )
                                  (if (>= efficiency target) "excellent"
                                      (if (>= efficiency (/ target u2)) "good"
                                          "needs-improvement")))
                    "no-targets")
      "no-data"
    )
  )
)
