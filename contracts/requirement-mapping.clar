;; Requirement Mapping Contract
;; Maps compliance training requirements to roles and departments

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-REQUIREMENT-NOT-FOUND (err u201))
(define-constant ERR-INVALID-INPUT (err u202))
(define-constant ERR-REQUIREMENT-EXISTS (err u203))

;; Data Variables
(define-data-var requirement-counter uint u0)

;; Requirement data structure
(define-map requirements
  uint
  {
    role: (string-ascii 50),
    department: (string-ascii 50),
    required-courses: (list 20 uint),
    renewal-period: uint,
    mandatory: bool,
    created-by: principal,
    created-at: uint,
    updated-at: uint
  }
)

;; Role-based requirement lookup
(define-map role-requirements
  (string-ascii 50)
  (list 10 uint)
)

;; Department-based requirement lookup
(define-map department-requirements
  (string-ascii 50)
  (list 10 uint)
)

;; User role mapping
(define-map user-roles
  principal
  {
    role: (string-ascii 50),
    department: (string-ascii 50),
    assigned-by: principal,
    assigned-at: uint
  }
)

;; Admin principals
(define-map admins
  principal
  bool
)

;; Initialize contract owner as admin
(map-set admins CONTRACT-OWNER true)

;; Read-only functions

(define-read-only (get-requirement (requirement-id uint))
  (map-get? requirements requirement-id)
)

(define-read-only (get-role-requirements (role (string-ascii 50)))
  (map-get? role-requirements role)
)

(define-read-only (get-department-requirements (department (string-ascii 50)))
  (map-get? department-requirements department)
)

(define-read-only (get-user-role (user principal))
  (map-get? user-roles user)
)

(define-read-only (get-user-requirements (user principal))
  (match (map-get? user-roles user)
    user-info (let
      (
        (role-reqs (default-to (list) (map-get? role-requirements (get role user-info))))
        (dept-reqs (default-to (list) (map-get? department-requirements (get department user-info))))
      )
      (some { role-requirements: role-reqs, department-requirements: dept-reqs })
    )
    none
  )
)

(define-read-only (is-training-required (user principal) (course-id uint))
  (match (get-user-requirements user)
    user-reqs (let
      (
        (role-reqs (get role-requirements user-reqs))
        (dept-reqs (get department-requirements user-reqs))
      )
      (or (is-some (index-of role-reqs course-id))
          (is-some (index-of dept-reqs course-id)))
    )
    false
  )
)

(define-read-only (get-total-requirements)
  (var-get requirement-counter)
)

(define-read-only (is-admin (user principal))
  (default-to false (map-get? admins user))
)

;; Public functions

(define-public (create-requirement
  (role (string-ascii 50))
  (department (string-ascii 50))
  (required-courses (list 20 uint))
  (renewal-period uint)
  (mandatory bool))
  (let
    (
      (new-requirement-id (+ (var-get requirement-counter) u1))
    )
    ;; Only admins can create requirements
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)

    ;; Validate inputs
    (asserts! (> (len role) u0) ERR-INVALID-INPUT)
    (asserts! (> (len department) u0) ERR-INVALID-INPUT)
    (asserts! (> (len required-courses) u0) ERR-INVALID-INPUT)

    ;; Create requirement record
    (map-set requirements new-requirement-id
      {
        role: role,
        department: department,
        required-courses: required-courses,
        renewal-period: renewal-period,
        mandatory: mandatory,
        created-by: tx-sender,
        created-at: block-height,
        updated-at: block-height
      }
    )

    ;; Update role requirements
    (let
      (
        (current-role-reqs (default-to (list) (map-get? role-requirements role)))
      )
      (map-set role-requirements role
        (unwrap! (as-max-len? (append current-role-reqs new-requirement-id) u10) ERR-INVALID-INPUT)
      )
    )

    ;; Update department requirements
    (let
      (
        (current-dept-reqs (default-to (list) (map-get? department-requirements department)))
      )
      (map-set department-requirements department
        (unwrap! (as-max-len? (append current-dept-reqs new-requirement-id) u10) ERR-INVALID-INPUT)
      )
    )

    ;; Update counter
    (var-set requirement-counter new-requirement-id)

    (ok new-requirement-id)
  )
)

(define-public (update-requirement
  (requirement-id uint)
  (required-courses (list 20 uint))
  (renewal-period uint)
  (mandatory bool))
  (let
    (
      (requirement (unwrap! (map-get? requirements requirement-id) ERR-REQUIREMENT-NOT-FOUND))
    )
    ;; Only admins can update requirements
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)

    ;; Validate inputs
    (asserts! (> (len required-courses) u0) ERR-INVALID-INPUT)

    ;; Update requirement
    (map-set requirements requirement-id
      (merge requirement
        {
          required-courses: required-courses,
          renewal-period: renewal-period,
          mandatory: mandatory,
          updated-at: block-height
        }
      )
    )

    (ok true)
  )
)

(define-public (assign-user-role
  (user principal)
  (role (string-ascii 50))
  (department (string-ascii 50)))
  (begin
    ;; Only admins can assign roles
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)

    ;; Validate inputs
    (asserts! (> (len role) u0) ERR-INVALID-INPUT)
    (asserts! (> (len department) u0) ERR-INVALID-INPUT)

    ;; Assign role to user
    (map-set user-roles user
      {
        role: role,
        department: department,
        assigned-by: tx-sender,
        assigned-at: block-height
      }
    )

    (ok true)
  )
)

(define-public (update-user-role
  (user principal)
  (role (string-ascii 50))
  (department (string-ascii 50)))
  (begin
    ;; Only admins can update roles
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)

    ;; Check if user has existing role
    (asserts! (is-some (map-get? user-roles user)) ERR-REQUIREMENT-NOT-FOUND)

    ;; Validate inputs
    (asserts! (> (len role) u0) ERR-INVALID-INPUT)
    (asserts! (> (len department) u0) ERR-INVALID-INPUT)

    ;; Update user role
    (map-set user-roles user
      {
        role: role,
        department: department,
        assigned-by: tx-sender,
        assigned-at: block-height
      }
    )

    (ok true)
  )
)

(define-public (remove-requirement (requirement-id uint))
  (let
    (
      (requirement (unwrap! (map-get? requirements requirement-id) ERR-REQUIREMENT-NOT-FOUND))
    )
    ;; Only admins can remove requirements
    (asserts! (is-admin tx-sender) ERR-NOT-AUTHORIZED)

    ;; Remove requirement
    (map-delete requirements requirement-id)

    ;; Note: We're not removing from role/department maps to maintain historical data
    ;; This prevents breaking existing user assignments

    (ok true)
  )
)

(define-public (check-user-compliance (user principal))
  (match (map-get? user-roles user)
    user-info (let
      (
        (role-reqs (default-to (list) (map-get? role-requirements (get role user-info))))
        (dept-reqs (default-to (list) (map-get? department-requirements (get department user-info))))
      )
      (ok {
        role: (get role user-info),
        department: (get department user-info),
        role-requirements: role-reqs,
        department-requirements: dept-reqs,
        total-requirements: (+ (len role-reqs) (len dept-reqs))
      })
    )
    ERR-REQUIREMENT-NOT-FOUND
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
