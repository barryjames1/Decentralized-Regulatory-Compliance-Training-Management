;; Training Provider Verification Contract
;; Manages verification and registration of training providers

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROVIDER-NOT-FOUND (err u101))
(define-constant ERR-PROVIDER-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-INPUT (err u103))

;; Data Variables
(define-data-var provider-counter uint u0)

;; Provider data structure
(define-map providers
  uint
  {
    name: (string-ascii 100),
    owner: principal,
    verified: bool,
    rating: uint,
    registration-date: uint,
    specialization: (string-ascii 100),
    courses-offered: uint
  }
)

;; Provider lookup by principal
(define-map provider-principals
  principal
  uint
)

;; Admin principals
(define-map admins
  principal
  bool
)

;; Initialize contract owner as admin
(map-set admins CONTRACT-OWNER true)

;; Read-only functions

(define-read-only (get-provider-info (provider-id uint))
  (map-get? providers provider-id)
)

(define-read-only (get-provider-by-principal (provider principal))
  (match (map-get? provider-principals provider)
    provider-id (map-get? providers provider-id)
    none
  )
)

(define-read-only (is-provider-verified (provider-id uint))
  (match (map-get? providers provider-id)
    provider (get verified provider)
    false
  )
)

(define-read-only (get-provider-rating (provider-id uint))
  (match (map-get? providers provider-id)
    provider (get rating provider)
    u0
  )
)

(define-read-only (get-total-providers)
  (var-get provider-counter)
)

(define-read-only (is-admin (user principal))
  (default-to false (map-get? admins user))
)

;; Public functions

(define-public (register-provider (name (string-ascii 100)) (specialization (string-ascii 100)))
  (let
    (
      (new-provider-id (+ (var-get provider-counter) u1))
    )
    ;; Check if provider already exists
    (asserts! (is-none (map-get? provider-principals tx-sender)) ERR-PROVIDER-ALREADY-EXISTS)

    ;; Validate inputs
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len specialization) u0) ERR-INVALID-INPUT)

    ;; Create provider record
    (map-set providers new-provider-id
      {
        name: name,
        owner: tx-sender,
        verified: false,
        rating: u0,
        registration-date: block-height,
        specialization: specialization,
        courses-offered: u0
      }
    )

    ;; Map principal to provider ID
    (map-set provider-principals tx-sender new-provider-id)

    ;; Update counter
    (var-set provider-counter new-provider-id)

    (ok new-provider-id)
  )
)

(define-public (verify-provider (provider-id uint))
  (let
    (
      (provider (unwrap! (map-get? providers provider-id) ERR-PROVIDER-NOT-FOUND))
    )
    ;; Only admins can verify providers
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)

    ;; Update provider status
    (map-set providers provider-id
      (merge provider { verified: true })
    )

    (ok true)
  )
)

(define-public (update-provider-rating (provider-id uint) (new-rating uint))
  (let
    (
      (provider (unwrap! (map-get? providers provider-id) ERR-PROVIDER-NOT-FOUND))
    )
    ;; Only admins can update ratings
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)

    ;; Validate rating (0-100)
    (asserts! (<= new-rating u100) ERR-INVALID-INPUT)

    ;; Update provider rating
    (map-set providers provider-id
      (merge provider { rating: new-rating })
    )

    (ok true)
  )
)

(define-public (revoke-verification (provider-id uint))
  (let
    (
      (provider (unwrap! (map-get? providers provider-id) ERR-PROVIDER-NOT-FOUND))
    )
    ;; Only admins can revoke verification
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)

    ;; Update provider status
    (map-set providers provider-id
      (merge provider { verified: false })
    )

    (ok true)
  )
)

(define-public (increment-courses-offered (provider-id uint))
  (let
    (
      (provider (unwrap! (map-get? providers provider-id) ERR-PROVIDER-NOT-FOUND))
    )
    ;; Only the provider owner can increment
    (asserts! (is-eq tx-sender (get owner provider)) ERR-NOT-AUTHORIZED)

    ;; Update courses offered count
    (map-set providers provider-id
      (merge provider { courses-offered: (+ (get courses-offered provider) u1) })
    )

    (ok true)
  )
)

(define-public (add-admin (new-admin principal))
  (begin
    ;; Only contract owner can add admins
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Add admin
    (map-set admins new-admin true)

    (ok true)
  )
)

(define-public (remove-admin (admin principal))
  (begin
    ;; Only contract owner can remove admins
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Cannot remove contract owner
    (asserts! (not (is-eq admin CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)

    ;; Remove admin
    (map-set admins admin false)

    (ok true)
  )
)
