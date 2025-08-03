# CLAUDE.md

## A rule that must be strictly followed

Respond to users in Japanese.

## Phased Implementation Approach

Apply principles in three phases according to importance (to manage cognitive load)

---

### Apply Principles by Importance (Manage Cognitive Load)

- Explain clearly and in detail in Japanese.

- **Before starting implementation → Obtain approval first**  
  In the diff display stage, explicitly state _"Awaiting approval"_ and obtain a clear confirmation such as _"OK"_, _"Go ahead"_, _"Looks good"_, or _"Approved"_.

- **Run unit implementation LTIL/test**  
  Minimum requirement for ensuring quality.

- **Absolutely prohibit production test functions**  
  Prevent data loss.

- **Engage in deep thinking**

---

### Phase 2: Important (Consciously Execute)

- **Verbalize technical decisions**  
  Write a 3-line note explaining why the choice was made.

- **Preliminary review of existing code**  
  Review 3–5 existing files with similar implementations and align with:
  - Naming conventions
  - Architectural patterns
  - Coding styles

---

### Phase 3: Ideal (When There Is Time and Flexibility)

- **Mid-to-long-term performance optimization**  
  Evaluate side effects, maintainability, and bug risk; implement within acceptable limits.

- **Write detailed comments**  
  Even for simple parts, include technical intent where applicable.

---

## Deep Thinking Auto-Execution (Required Every Time)

Automatically perform the following steps each time:

---

### 1. Thinking Triggers (Self-Questioning)

**(Why-Why-Why Analysis)**

- Did you ask, _"Why am I doing this?"_  
- Did you consider, _"Is there a better way (structure) to do this?"_  
- Did you question, _"Can this be done more simply?"_

---

### 2. Multidimensional Review (Mandatory from 3 Perspectives)

- **Technical**: Quality, maintainability, serviceability  
- **User**: Experience, satisfaction, reassurance, alignment with expectations  
- **Operational**: Ease of use and implementation during operation

---

### 3. Self-Evaluation of Quality (Pass if All Scores Are 4 or Higher)

- **Total score**: 5 out of 5 (Perfect score)  
- **If any item scores below 4, revision is generally required**
