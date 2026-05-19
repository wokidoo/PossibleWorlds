1. What are you trying to do? Articulate your objectives using absolutely no jargon.
    Create a system that captures the beliefs and ideals of characters allowing to simulate interpersonal and group dynamics such as conflicts and partnerships. Also, simulate the spreading of both factual and false information.

2. How is it done today, and what are the limits of current practice?
    **PsychSim**

        Description: A multi-agent simulation tool developed (at USC/ICT) for modelling agents with beliefs about the world and beliefs about other agents (i.e., theory of mind).

        Features: Agents maintain probabilistic beliefs, model other agents’ beliefs, make decisions accordingly, and interact.

        Relevance: Strong on beliefs + interaction; may be good as a starting point for modelling internal states.

        Note: More a research tool than a commercial ‘game’.

        (I couldn’t easily find a recent full open-source link in this search, but references appear in literature.)

    **Do Role‑Playing Agents Practice What They Preach? (2025, Orgad et al.)**

        Description: A study using large language model (LLM) agents playing the Trust Game with synthetic personas (with beliefs, personality traits) and measuring belief-behaviour consistency.
        arXiv

        Features: Each agent persona has beliefs & attributes; the simulation explores whether the agent acts consistently with those beliefs; multi-round interaction between agents.

        Relevance: Good for exploring belief/ideal vs behaviour consistency and multi-agent interaction.

        Limitation: It is more experiment than a general “world simulation with group dynamics”.

    **Simulating Theory and Society: How Multi‑Agent Artificial Intelligence Modeling Contributes to … (Shults, 2025)**

        Description: A review/discussion article about multi-agent artificial intelligence modelling (MAAI) and its potential for social theory, i.e., agents in networks interacting, micro→macro emergence.
        SpringerLink

        Features: Emphasises psychologically realistic agents in sociological networks; discusses how beliefs/attitudes in agents plus interactions can produce macro phenomena.

        Relevance: Good theoretical framing of your interest (beliefs + group interaction) though it doesn’t present a single ready-system.

        Limitation: More conceptual than a particular simulation you can run.

    **A Model of Multi‑Agent Consensus for Vague and Uncertain Beliefs (Crosscombe & Lawry, 2016)**

        Description: Simulation of agents whose beliefs are vague/uncertain (three truth states + probabilistic), interacting under bounded confidence to form consensus.
        arXiv

        Features: Agents have belief states, update beliefs via interaction; focuses on consensus/dynamics of beliefs across a network.

        Relevance: Good for modelling belief propagation and change in a group, though “ideals/values” are less explicitly modelled.

        Limitation: Simpler belief model, less rich “ideal systems” or identity/groups.

    **Modeling agents with a theory of mind: theory‑theory versus simulation‑theory (Harbers et al., 2012)**

        Description: Investigates modelling an agent’s theory of mind — i.e., agent has beliefs about other agents’ beliefs/goals — within BDI agents.
        publications.tno.nl

        Features: Focus on nested beliefs (A believes that B believes X) and how agents reason about others.

        Relevance: Very relevant for character-level belief/ideal modelling + interpersonal interactions.

        Limitation: Doesn’t necessarily simulate large groups or values/ideals in a rich ideological sense.

    **NPCs to Believe In: Value‑based Morality in Video Game Characters (2024)**

        Description: A game-research paper about implementing value-based morality (beliefs/ideals) in NPC characters and how players perceive them.
        eScholarship

        Features: Focus on characters having moral/value systems, beliefs about what is right/wrong; some interactive game context.

        Relevance: Bridges into games (not purely academic) and touches on beliefs/ideals in characters.

        Limitation: Likely more limited in scale (group interaction of many agents) than full social simulation.

    **Republic: The Revolution (2003)**

        Description: A political strategy game where each “citizen” and district has ideology scores (Force, Influence, Wealth) and the game simulates ideological change/influence.
        Wikipedia

        Features: Ideology is modelled (though simplified) and influences interpersonal and group/faction interactions.

        Relevance: Good example of a game attempting to model beliefs/ideals (via ideology) and grouping/faction dynamics.

        Limitation: Critics say the ideological model was shallow (“depth of rock, paper scissors”).
        Wikipedia

    **3APL (Abstract Agent Programming Language)**

        Description: A programming language/platform for BDI (Belief-Desire-Intention) agents: agents defined with belief base, goals (desires) and plans (intentions).
        Wikipedia
        +1

        Features: Allows specification of agents with beliefs and desires, ability to communicate between agents, multi-agent interaction in environment.

        Relevance: While more tool than simulation world, it gives you building blocks to implement belief/ideal simulations.

        Limitation: Doesn’t come with ready-made social world / group dynamics; you’d build it.

    **A Reputation Game Simulation: Emergent Social Behaviour from Opinion‑based Communication (Enßlin, 2022)**

        Description: A game-style simulation where agents maintain opinions about others (reputations) and through communication these evolve; emergent social dynamics studied.
        Wiley Online Library

        Features: Focus on interpersonal beliefs/ideals (opinions/reputation) and how they change via interaction; group behaviour emerges.

        Relevance: Closer to your interest of interpersonal + group simulation with beliefs.

        Limitation: Probably less full spectrum of “ideals” (value systems) or nested beliefs.

        NPCs to Believe In: Value‑based Morality in Video Game Characters [Oops this is duplicate of #6]

    **Interactive inference: a multi‑agent model of cooperative joint actions (Maisto et al., 2022)**

        Description: Model where multiple agents maintain probabilistic beliefs about a shared goal and infer each other’s intentions/beliefs to coordinate action.
        arXiv

        Features: Focus on belief alignment, interactive inference, joint action — so modelling interpersonal coordination and belief convergence.

        Relevance: Good for modelling how agents interact, align beliefs/ideals, and form groups or coordinate behaviour.

        Limitation: More about coordination than ideology or rich value systems.

3. What is new in your approach and why do you think it will be successful?
    With the exception of
4. Who cares? If you are successful, what difference will it make?

5. What are the risks?

6. How much will it cost?

7. How long will it take?

8. What are the mid-term and final “exams” to check for success?
