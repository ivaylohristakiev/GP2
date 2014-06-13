module Search where

import Prelude hiding (lookup)
import Data.List
import Data.Maybe
import Control.Monad (guard)

import ExAr
import GPGraph
import Graph
import GPSyntax

type RuleNodeId = NodeId
type HostNodeId = NodeId
type RuleEdgeId = EdgeId
type HostEdgeId = EdgeId

type Subst a = [(ID, a)]

type GraphMorphism = ( [NodeMatch], [EdgeMatch] ) 
type NodeMatch = (RuleNodeId, HostNodeId, Subst [HostAtom])
type EdgeMatch = (RuleEdgeId, HostEdgeId, Subst [HostAtom])



notImplemented = error "Not implemented"

substExtend :: Subst [HostAtom] -> ID -> [HostAtom] -> Maybe ( Subst [HostAtom] )
substExtend s id atoms = Just $ (id, atoms):s

-- indeg and outdeg not yet implemented
-- due to requirement for graph context and
-- ids of other nodes?
atomsMatch :: [HostAtom] -> [RuleAtom] -> Maybe (Subst [HostAtom])
atomsMatch = atomsMatchWith []

-- ListVar matching multiple elems is not yet 
-- implemented
atomsMatchWith :: Subst [HostAtom] -> [HostAtom] -> [RuleAtom] -> Maybe (Subst [HostAtom])
atomsMatchWith s [] [] = Just s
atomsMatchWith s hall@(ha:has) (ra:ras) =
    case (ha, ra) of
        ( _    , Var (var, ListVar) ) ->
            case compare hl rl of
                LT -> Nothing
                EQ -> do 
                    s' <- substExtend s var []
                    atomsMatchWith s' hall ras
                GT -> do
                    s' <- substExtend s var $ take n hall
                    atomsMatchWith s' (drop n hall) ras
            where
                hl = length hall
                rl = length ras
                n  = hl - rl                
        ( Int i, Val (Int j) ) -> do
            guard $ i == j
            atomsMatchWith s has ras
        ( Int i, Var (var, vt) ) -> do
            guard $ IntVar <= vt
            s' <- substExtend s var [ha]
            atomsMatchWith s' has ras
        ( Chr c, Val (Chr d) ) -> do
            guard $ c == d
            atomsMatchWith s has ras
        ( Chr c, Var (var, vt) ) -> do
            guard $ ChrVar <= vt
            s' <- substExtend s var [ha]
            atomsMatchWith s' has ras
        ( Str str, Val (Str t) ) -> do
            guard $ str == t
            atomsMatchWith s has ras
        ( Str str, Var (var, vt) ) -> do
            guard $ StrVar <= vt
            s' <- substExtend s var [ha]
            atomsMatchWith s' has ras

colourMatch :: Colour -> Colour -> Bool
colourMatch _  Cyan = True
colourMatch hc rc   = (hc == rc)

doLabelsMatch :: HostLabel -> RuleLabel -> Maybe (Subst [HostAtom])
doLabelsMatch (HostLabel has hc) (RuleLabel ras rc) = if colourMatch hc rc then atomsMatch has ras else Nothing

doNodesMatch :: HostGraph -> RuleGraph -> HostNodeId -> RuleNodeId -> Maybe (Subst [HostAtom])
doNodesMatch h r hid rid = doLabelsMatch hlab rlab
    where  -- todo: add error checking!
        HostNode _ _ hlab = fromJust (nLabel h hid)
        RuleNode _ _ rlab = fromJust (nLabel r rid)

-- Also check for matching source and target? TODO: add error checking
doEdgesMatch :: HostGraph -> RuleGraph -> HostEdgeId -> RuleEdgeId -> Maybe (Subst [HostAtom])
doEdgesMatch h r hid rid = doLabelsMatch (fromJust $ eLabel h hid) (fromJust $ eLabel r rid)

{-
-- Returns every hostNode that matches a given ruleNode.
matchRuleNode :: HostGraph -> RuleGraph -> RuleNodeId -> [NodeMatch]
matchRuleNode h r rn =
    [ (rn, n, fromJust $ doNodesMatch h r n rn) | n <- allNodes h , isJust $ doNodesMatch h r n rn ]

-- Returns every hostEdge that matches a given ruleEdge
matchRuleEdge :: HostGraph -> RuleGraph -> RuleEdgeId -> [EdgeMatch]
matchRuleEdge h r re =
    [ (re, he, fromJust $ doEdgesMatch h r he re) | he <- allEdges h , isJust $ doEdgesMatch h r he re ]

-- Needs to be permuted with matchRuleEdge, and then impossible matches (where
--   nodes and edges are incompatible) need to be filtered out.
matchNodes :: HostGraph -> RuleGraph -> [[NodeMatch]]
matchNodes h r = map ( matchRuleNode h r ) $ allNodes r

matchEdges :: HostGraph -> RuleGraph -> [[EdgeMatch]]
matchEdges h r = map ( matchRuleEdge h r ) $ allEdges r

-- should be taking a search-plan approach: start with an arbitrary node
--   and extend the match as far as possible
matchGraph :: HostGraph -> RuleGraph -> [GraphMorphism]
matchGraph = notImplemented
--matchGraph g r = [ (nm, em) | nm <- matchNodes g r , em <- matchEdges g r ]
-}


-- matching the graph is a generalisation of a parsing task! 
-- Our parser consumes a host graph _and_ a rule graph, returning the unconsumed parts of the graphs
-- plus a possible NodeMatch or EdgeMatch

type Matcher a = RuleGraph -> HostGraph -> [(RuleGraph, HostGraph, a)]

pure :: a -> Matcher a
pure x = \r h -> [(r, h, x)]

infixl 4 °

(°) :: Matcher (a -> b) -> Matcher a -> Matcher b
f ° a = \h -> [(h1, g b) | (h0, g) <- f h, (h1, b) <- a h0]

matchRuleNode :: RuleGraph -> RuleNodeId -> Matcher NodeMatch
matchRuleNode r rnid h = notImplemented
    where
        r' = rmNode r rnid

matchRuleEdge :: RuleGraph -> RuleEdgeId -> Matcher EdgeMatch
matchRuleEdge r reid h = notImplemented
    where
        r' = rmEdge r reid

matchGraph :: RuleGraph -> Matcher GraphMorphism
matchGraph r h = notImplemented


{-
makeTestGraph n = nReLabel gr id (HostLabel [] Green)
    where
        gr = k n
        id = head $ allNodes gr

--makeRuleGraph n = makeTestGraph

testGraph = makeTestGraph 3
--searchFor = makeRuleGraph 2


-- two nodes are equal if their labels are equal
nodesMatch g r gn rn = nLabel g gn == nLabel r rn

-- two edges are equal if their labels are equal AND the nodes on either end are equal
edgesMatch :: HostGraph -> RuleGraph -> HostEdgeId -> RuleEdgeId -> Bool
edgesMatch g r ge re = ( eLabel g ge == eLabel r re )
                       && ( nodesMatch g r (fromJust $ source g ge) (fromJust $ source r re) )
                       && ( nodesMatch g r (fromJust $ target g ge) (fromJust $ target r re) )
       
matchRuleNode :: HostGraph -> RuleGraph -> RuleNodeId -> NodeMatches
matchRuleNode g r rn =
    [ (rn, n) | n <- allNodes g , nodesMatch g r n rn ]

matchRuleEdge :: HostGraph -> RuleGraph -> RuleEdgeId -> EdgeMatches
matchRuleEdge g r re =
    [ (re, e) | e <- allEdges g , edgesMatch g r e re ]

matchNodes :: HostGraph -> RuleGraph -> NodeMatches
matchNodes g r = concatMap ( matchRuleNode g r ) $ allNodes r

matchEdges :: HostGraph -> RuleGraph -> EdgeMatches
matchEdges g r = concatMap ( matchRuleEdge g r ) $ allEdges r
{-matchEdges g r (rn, gn) = union ins outs
    where
        ins  = filter (uncurry $ edgesMatch g r)
                    [ (re, e) | e <- inEdges g gn, re <- inEdges r rn ]
        outs = filter (uncurry $ edgesMatch g r)
                    [ (re, e) | e <- outEdges g gn, re <- outEdges r rn ] -}

matchGraph :: HostGraph -> RuleGraph -> [GraphMorphism]
matchGraph g r = [ (nm, em) | nm <- matchNodes g r , em <- matchEdges g r ]

-}                


