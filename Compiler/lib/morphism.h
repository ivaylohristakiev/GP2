/* ///////////////////////////////////////////////////////////////////////////

  ===============
  Morphism Module
  ===============
 
  Defines a data structure for a graph morphism. Morphisms represent matches
  from the left-hand graph of a rule to a subgraph of the host graph. 
  Specifically, a morphism consists of a set of node-to-node mappings, 
  a set of edge-to-edge mappings, and a set of variable-value mappings.
                            
/////////////////////////////////////////////////////////////////////////// */

#ifndef INC_MATCH_H
#define INC_MATCH_H

#include "globals.h"
#include "label.h"

typedef enum {NO_ASSIGNMENT = 0, INTEGER_ASSIGNMENT, STRING_ASSIGNMENT,
              LIST_ASSIGNMENT} AssignmentType;
/* Association list to represent variable-value mappings. The type of an 
 * assignment is the type of its value. This is either INTEGER_VAR, STRING_VAR
 * or LIST_VAR. */
typedef struct Assignment {
   AssignmentType type;
   HostList *value;
} Assignment;

typedef struct Map {
   int host_index;
   /* The number of variable-value assignments added by this node map.
    * Needed when matching backtracks in order to remove the appropriate
    * number of assignments from the morphism. */
   int assignments;
} Map;

/* A graph morphism is a set of node-to-node mappings, a set of edge-to-edge
 * mappings and a variable-value assignment. Maps and assignments are
 * stored as static arrays, whose sizes are determined at compile time by
 * the number of nodes, edges and variables in the rule. */
typedef struct Morphism {
   int nodes;
   Map *node_map;

   int edges;
   Map *edge_map;

   int variables;
   Assignment *assignment;

   /* Stack to record the order of variable assignments during rule matching. */
   int *assigned_variables;
   int variable_index;
} Morphism;


/* Allocates memory for the morphism, and calls initialiseMorphism. */
Morphism *makeMorphism(int nodes, int edges, int variables);

/* This function is used to both initialise the morphism on creation and to 
 * reset the morphism after each rule application. The data in the morphism
 * are reset to their default values. */
void initialiseMorphism(Morphism *morphism);
void addNodeMap(Morphism *morphism, int left_index, int host_index, int assignments);
void removeNodeMap(Morphism *morphism, int left_index);
void addEdgeMap(Morphism *morphism, int left_index, int host_index, int assignments);
void removeEdgeMap(Morphism *morphism, int left_index);
void addAssignment(Morphism *morphism, int id, AssignmentType type, HostList *value);
void removeAssignments(Morphism *morphism, int number);
void pushVariableId(Morphism *morphism, int id);
int popVariableId(Morphism *morphism);

int lookupNode(Morphism *morphism, int left_index);
int lookupEdge(Morphism *morphism, int left_index);
Assignment lookupAssignment(Morphism *morphism, int id);

/* Tests a potential variable-value assignment against the assignments in the
 * morphism. If the variable is not in the assignment, its name and value are 
 * added to the assignments array in the morphism. 
 *
 * Returns -1 if the variable has already been assigned to a different value
 * in the assignment.
 * Returns 0 if the variable has a value in the assignment that is equal to
 * the passed value.
 * Returns 1 if the variable did not previously exist in the assignment. */
int addListAssignment(Morphism *morphism, int id, HostList *list);
int addIntegerAssignment(Morphism *morphism, int id, int value);
int addStringAssignment(Morphism *morphism, int id, string value);

/* These functions expect to be passed a variable of the appropriate type. */
int getIntegerValue(Morphism *morphism, int id);
string getStringValue(Morphism *morphism, int id);
HostList *getListValue(Morphism *morphism, int id);

/* Used to test string constants in the rule against a host string. If 
 * rule_string is a prefix of the host_string, then the index of the host 
 * character directly after this prefix is returned, so that the caller knows
 * where in the host string to resume matching. 
 * For example, isPrefix("ab", "abcd") returns 2, the index of the first 
 * character ('c') after the matched substring ("ab").
 * Returns -1 if it the rule string is not a prefix of the host string. */
int isPrefix(const string rule_string, const string host_string);

/* Analogous to isPrefix. Example: isSuffix("cd", "abcd") returns 1, the index
 * of the character ('b') directly preceding the matched suffix ("cd"). 
 * The exception is if rule_string equals host_string, in which case 0 is
 * returned. */
int isSuffix(const string rule_string, const string host_string);

void printMorphism(Morphism *morphism);
void freeMorphism(Morphism *morphism);
 
#endif /* INC_MATCH_H */