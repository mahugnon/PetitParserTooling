Class {
	#name : #PPTGeneratorVisitor,
	#superclass : #Object,
	#instVars : [
		'generationStrategy',
		'ruleReifications',
		'ruleRenaming'
	],
	#category : #'PetitParserTooling-Core'
}

{ #category : #'instance creation' }
PPTGeneratorVisitor class >> newWithStrategy: aPPASTGeneratorStrategy onRule: aRule [
	^ self new
		generationStrategy: aPPASTGeneratorStrategy;
		configureOn: aRule;
		yourself
]

{ #category : #config }
PPTGeneratorVisitor >> configureOn: aRuleMethod [
	self
		ruleReifications:
			(aRuleMethod pragmas
				select: [ :aPragma | aPragma key = 'reify:into:' ]
				thenCollect: [ :aValidPragma | 
					(aValidPragma arguments first reject: [ :el | el = #/ ])
						-> aValidPragma arguments second ]) asDictionary.
	self
		ruleRenaming:
			(aRuleMethod pragmas
				select: [ :aPragma | aPragma key = 'rename:into:' ]
				thenCollect:
					[ :aValidPragma | aValidPragma arguments first -> aValidPragma arguments second ])
				asDictionary
]

{ #category : #accessing }
PPTGeneratorVisitor >> generationStrategy [
	^ generationStrategy
]

{ #category : #accessing }
PPTGeneratorVisitor >> generationStrategy: anObject [
	generationStrategy := anObject
]

{ #category : #initialization }
PPTGeneratorVisitor >> initialize [ 
	super initialize.
	self ruleReifications: Dictionary new
]

{ #category : #testing }
PPTGeneratorVisitor >> isASeparatedBy: aPP2ActionNode [
	^ aPP2ActionNode child children second child children second
		= aPP2ActionNode child children first
]

{ #category : #accessing }
PPTGeneratorVisitor >> ruleReifications [
	^ ruleReifications
]

{ #category : #accessing }
PPTGeneratorVisitor >> ruleReifications: anObject [
	ruleReifications := anObject
]

{ #category : #accessing }
PPTGeneratorVisitor >> ruleRenaming [
	^ ruleRenaming
]

{ #category : #accessing }
PPTGeneratorVisitor >> ruleRenaming: anObject [
	ruleRenaming := anObject
]
