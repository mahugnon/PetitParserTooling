"
I am a generator that create an AST from a PetitParser grammar (a subclass of PPCompositeNode or PP2CompositeNode).

I base my generation on the rules and use pragma available in grammar rules: 
	<astAttributeRename: #identifier into: #functionName>
"
Class {
	#name : #PPTASTGenerator,
	#superclass : #Object,
	#category : #'PetitParserTooling-Core'
}

{ #category : #creation }
PPTASTGenerator class >> createASTNodeForRule: aRule ruleStructure: aRuleStructure generationStrategy: aGenerationStrategy [
	| astClass |
	astClass := aGenerationStrategy createAstNodeClass: aRule.
	aRuleStructure attributesToCreate
		do: [ :subRuleName | 
			aGenerationStrategy
				createAttributeAndAccessorsFor: subRuleName
				inClass: astClass ].
	astClass
		compile:
			'acceptVisitor: aVisitor
	<generated>
	^ aVisitor visit' , astClass name , ': self'
		classified: #visiting
]

{ #category : #generation }
PPTASTGenerator class >> createFlattenNodeForRule: aRule generationStrategy: aPPASTGeneratorStrategy [
	| astClass |
	astClass := Object
		subclass: (aPPASTGeneratorStrategy astNodeClassNameForRule: aRule)
		instanceVariableNames: aRule
		classVariableNames: ''
		package: aPPASTGeneratorStrategy astPackage.
	astClass
		compile:
			'acceptVisitor: aVisitor
	<generated>
	^ aVisitor visit' , astClass name , ': self'
		classified: #visiting.
	(RBCreateAccessorsForVariableRefactoring
		variable: aRule
		class: astClass
		classVariable: false) execute
]

{ #category : #generation }
PPTASTGenerator class >> createFlattenRule: aRuleName inParserFollowingGenerationStrategy: aPPASTGeneratorStrategy [
	(self class environment at: aPPASTGeneratorStrategy parserClass)
		compile:
			aRuleName
				,
					'
	<generated>
	^ super ' , aRuleName , ' flatten ==> [ :production | '
				, (aPPASTGeneratorStrategy astNodeClassNameForRule: aRuleName)
				, ' new ' , aRuleName , ': production; yourself ]'
		classified: 'rules'
]

{ #category : #generation }
PPTASTGenerator class >> createFlattenVisitingMethod: aRule generationStrategy: aPPASTGeneratorStrategy [
	| astNodeClass |
	astNodeClass := aPPASTGeneratorStrategy
		astNodeClassNameForRule: aRule.
	(self class environment at: aPPASTGeneratorStrategy visitorClass)
		compile:
			'visit' , astNodeClass , ': an' , astNodeClass
				,
					'
	<generated>
	^ an' , astNodeClass , ' ' , aRule
		classified: #visiting
]

{ #category : #creation }
PPTASTGenerator class >> createParserForRule: aRule ruleStructure: aRuleStructure generationStrategy: aGenerationStrategy [
	| parserClass |
	parserClass := self class environment
		at: aGenerationStrategy parserClass.
	parserClass
		compile:
			aRule
				,
					'
	<generated>
	^ super ' , aRule , ' ==> [ :production | '
				, (aGenerationStrategy astNodeClassNameForRule: aRule) , ' new '
				, (aRuleStructure methodCodeWith: 'production') , ' ]'
]

{ #category : #parserGeneration }
PPTASTGenerator class >> ensureParserClassFrom: aPPASTGeneratorStrategy existWithSuperclass: aClass [
	| parserClass |
	parserClass := [ self class environment
		at: aPPASTGeneratorStrategy parserClass ]
		on: NotFound
		do: [ aClass
				subclass: aPPASTGeneratorStrategy parserClass
				instanceVariableNames: ''
				classVariableNames: ''
				package: aPPASTGeneratorStrategy parserPackage ].
	parserClass
		compile:
			'rejectSeparators: anArray
	<generated>
	^ anArray withIndexSelect: [:anElement :anIndex | anIndex odd]'
		classified: #helpers.
	parserClass
		compile:
			'selectSeparators: anArray
	<generated>
	^ anArray withIndexSelect: [:anElement :anIndex | anIndex even]'
		classified: #helpers
]

{ #category : #parserGeneration }
PPTASTGenerator class >> ensureVisitorClassFrom: aPPASTGeneratorStrategy [
	[ self class environment at: aPPASTGeneratorStrategy visitorClass ]
		on: NotFound
		do: [ Object
				subclass: aPPASTGeneratorStrategy visitorClass
				instanceVariableNames: ''
				classVariableNames: ''
				package: aPPASTGeneratorStrategy visitorPackage ]
]

{ #category : #'as yet unclassified' }
PPTASTGenerator class >> generateEverythingFrom: aGrammarClass generationStrategy: aGenerationStrategy [
	| grammar |
	self
		ensureParserClassFrom: aGenerationStrategy
		existWithSuperclass: aGrammarClass.
	self ensureVisitorClassFrom: aGenerationStrategy.
	grammar := aGrammarClass new.
	grammar productionNames
		do: [ :aGrammarRule | 
			aGenerationStrategy
				if: aGrammarRule
				shouldBeFlatten: [ self
						createFlattenNodeForRule: aGrammarRule
						generationStrategy: aGenerationStrategy.
					self
						createFlattenRule: aGrammarRule
						inParserFollowingGenerationStrategy: aGenerationStrategy.
					self
						createFlattenVisitingMethod: aGrammarRule
						generationStrategy: aGenerationStrategy ]
				else: [ 
					|ruleStructure|
					ruleStructure := self obtainRuleStructureFor: aGrammarRule 
						generationStrategy: aGenerationStrategy
						grammar: grammar.
					self createASTNodeForRule: aGrammarRule  ruleStructure: ruleStructure generationStrategy: aGenerationStrategy.
					self createParserForRule: aGrammarRule  ruleStructure: ruleStructure generationStrategy: aGenerationStrategy.
					
					"self
						createVisitingMethod: aGrammarRule
						generationStrategy: aGenerationStrategy
						grammar: grammar" ] ]
]

{ #category : #construction }
PPTASTGenerator class >> obtainRuleStructureFor: aRule generationStrategy: aPPASTGeneratorStrategy grammar: aGrammarPPInstance [
	^ [ (aGrammarPPInstance productionAt: aRule) child
		accept:
			(PPTRuleStructureBuilderVisitor
				newWithStrategy: aPPASTGeneratorStrategy
				onRule: (aGrammarPPInstance class lookupSelector: aRule)) ]
		on: PPTChoiceReificationNotDefined
		do: [ :exception | 
			exception contextNode = (aGrammarPPInstance productionAt: aRule) child
				ifTrue:
					[ "In this case, the choice that is not reify is the direct child of the rule, so we will use directly the choice as a leaf" PPTRuleLeaf name: aRule ]
				ifFalse: [ exception
						rule: aRule;
						signal ] ]
]
