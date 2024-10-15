ArchitectElevatorAWS/
│
├── modules/
│   ├── networking/
│   ├── compute/
│   ├── database/
│   ├── security/
│   ├── monitoring/
│   └── shared-services/
│ 
├── environments/
│   ├── management/
│   ├── security/
│   ├── shared/
│   ├── network/
│   ├── dev/
│   ├── staging/
│   └── prod/
│
├── config/
│   ├── common-variables.tf
│   └── common.tfvars
│
├── teams/
│   ├── business-domain-a/
│   ├── business-domain-b/
│   └── platform/
│
├── policies/
│   ├── governance/
│   └── compliance/
│
├── scripts/
│   ├── ci-cd/
│   └── automation/
│
├── decision-records/
│
├── docs/
│   ├── runbooks/
│   └── architecture-overview/
│
├── tests/
│   ├── unit/
│   └── integration/
│
├── .gitignore
├── README.md
└── main.tf

1. <mark style="background: #ABF7F7A6;">Accounts</mark>: 
	* Vertical Cohesion:  By having separate accounts for management, security, shared services, networking, it is enabling teams to own their entire stack and make end-to-end decisions within their domain
	* Three Kinds of Architecture: It separates business architecture (management, devstg, prod), information architecture (shared, security), and technology architecture (network)
	* Governance Through Infrastructure:  By centralizing these critical functions, it can enforce standards and compliance requirements across the organization without relying solely on policy documents
    
1. <mark class="hltr-cyan">Modules</mark>: Reflects the "Three Kinds of Architecture" principle, allowing for reusable components across business and technical domains.

	- Business modules to align with business domains
	- Information modules to handle data and integration
	- Technology modules to encapsulate specific tech stacks  
	  
	 <mark class="hltr-yellow">This separation enables reuse and flexibility across different parts of the organization.</mark>

4. Config:

1. <mark class="hltr-cyan">Environments</mark>:  
    - Rapid prototyping and experimentation in dev
    - Realistic testing in staging
    - Controlled releases to production  
      
<mark style="background: #FFF3A3A6;">This supports the Build-Measure-Learn cycle, allowing quick feedback and iteration across all stages of development and deployment</mark>


6. <mark class="hltr-cyan">Teams</mark>:  "Vertical Cohesion", enabling teams to own their entire stack while using shared modules.
   
	- Empowers teams to make end-to-end decisions
	- Reduces dependencies between teams
	- Allows for faster iteration within a business domain  
	    
<mark class="hltr-yellow">	Shared modules ensure consistency and prevent duplication across teams.</mark>


1. <mark class="hltr-cyan">Policies</mark>: Implements "Governance Through Inception" by codifying standards and compliance requirements.

	- Standards are enforced automatically
	- Compliance is built into the development workflow
	- Teams can self-govern within established guidelines


3. <mark class="hltr-cyan">Scripts</mark>: Supports "Automation" principles  and "Economies of Speed"

	- Repeatable processes
	- Reduced human error
	- Faster deployment and testing cycles  
<mark class="hltr-yellow">	Faster iteration provides competitive advantage</mark>

1. <mark class="hltr-cyan">Docs</mark>:
	1. Architecture Decision Records: 
		- Capture the context and rationale behind decisions 
		- Encourage questioning assumptions
		- Provide a historical record for future reference
		  
	1. Diagrams:
		- Use visual representations to drive design discussions 
		- Communicate complex ideas more effectively  
		- Serve as a shared reference point for teams
		
	1. Runbooks:
		- Document operational procedures  
		- Enable consistent handling of incidents  
		- Support the principle that it can't fake operational excellence
    
7. <mark class="hltr-cyan">Tests</mark>: Enables "Fast and Good" development and supports the "Build-Measure-Learn" cycle

	- Enables confident, rapid changes 
	- Provides quick feedback in the Build-Measure-Learn cycle 
	- Allows for continuous validation of the system's behavior

