module PrintGraph (makePrintableGraph) where

import Graph
import GPSyntax
import Mapping

-- Converts a host graph to a "printable graph" G. G is identical to the host
-- graph except that its nodes and edges have been converted to strings in
-- correspondence with GP 2's textual syntax.

type PrintableGraph = Graph String String

-- NodeId mapping from the old graph to the new graph.
type NodeMap = Mapping NodeId NodeId

-- Structurally this operates similarly to the makeGraph functions in ProcessAst.hs.
-- I refer you to the function descriptions in that file. The string labels of the
-- output graph are generated by calling auxiliary functions to convert outputs
-- of nLabel and eLabel to strings.

makePrintableGraph :: HostGraph -> PrintableGraph
makePrintableGraph h = fst $ foldr (makeEdge h) (nodeGraph, nodeMaps) (allEdges h)
    where (nodeGraph, nodeMaps) = foldr (makeNode h) (emptyGraph, []) (allNodes h)

makeNode :: HostGraph -> NodeId -> (PrintableGraph, NodeMap) -> (PrintableGraph, NodeMap)
makeNode h nid (g, nm) = (g', (nid, newId):nm)
    where (g', newId) = newNode g (printHostNode h nid)

makeEdge :: HostGraph -> EdgeId -> (PrintableGraph, NodeMap) -> (PrintableGraph, NodeMap)
makeEdge h eid (g, nm) = (g', nm) 
    where srcId   = definiteLookup (source h eid) nm
          tgtId   = definiteLookup (target h eid) nm
          (g', _) = newEdge g srcId tgtId $ printHostEdge h eid

printHostNode :: HostGraph -> NodeId -> String
printHostNode h nid = root ++ printHostLabel label
    where root = if isRoot then " (R)" else "" 
          HostNode _ isRoot label = nLabel h nid

printHostEdge :: HostGraph -> EdgeId -> String
printHostEdge h eid = printHostLabel $ eLabel h eid

printHostLabel :: HostLabel -> String
printHostLabel (HostLabel atoms colour) = label ++ printColour colour
    where label = if null atoms
                  then "empty"
                  -- init is called to drop the trailing colon. 
                  else init $ concatMap printValue atoms 
          printValue (Int i) = show i ++ ":"
          printValue (Chr c) = show c ++ ":"
          printValue (Str s) = show s ++ ":"

-- Cyan is a member of data type Colour but should never appear in a host
-- graph label.

printColour :: Colour -> String
printColour Uncoloured = ""
printColour Red = " # red"
printColour Green = " # green"
printColour Blue = " # blue"
printColour Grey = " # grey"
printColour Dashed = " # dashed"


