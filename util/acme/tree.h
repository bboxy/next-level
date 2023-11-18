// ACME - a crossassembler for producing 6502/65c02/65816/65ce02 code.
// Copyright (C) 1998-2021 Marco Baye
// Have a look at "acme.c" for further info
//
// tree stuff
#ifndef tree_H
#define tree_H


#include <stdio.h>	// for FILE
#include "config.h"


// macros for pre-defining tree node tables
#define PREDEF_START		{NULL, NULL, 0, NULL, NULL}	// this is used to determine if list has been made into tree yet
#define PREDEFNODE(s, v)	{NULL, NULL, 1, s, (void *) (v)}
#define PREDEF_END(s, v)	{NULL, NULL, 0, s, (void *) (v)}

// type definitions

typedef unsigned int	hash_t;	// must be unsigned, otherwise the hash algorithm won't be very useful!

// tree node structure type definition for lookups in "read-only" (i.e. keyword) trees
struct ronode {
	struct ronode	*greater_than;	// pointer to sub-tree
	struct ronode	*less_than_or_equal;	// pointer to sub-tree
	hash_t		hash_value;
	const char	*id_string;	// name, zero-terminated
	void		*body;		// bytes, handles or handler function
};

// tree node structure type definition for "read/write" items, i.e. macros/symbols
struct rwnode {
	struct rwnode	*greater_than;	// pointer to sub-tree
	struct rwnode	*less_than_or_equal;	// pointer to sub-tree
	hash_t		hash_value;
	char		*id_string;	// name, zero-terminated
	void		*body;		// macro/symbol body
	int		id_number;	// scope number
};


// prototypes

// Search for a given ID string in a given tree. Store "body" component in
// node_body and return TRUE. Return FALSE if no matching item found.
struct dynabuf;
extern int Tree_easy_scan(struct ronode *tree, void **node_body, struct dynabuf *dyna_buf);
// Search for a "RAM tree" item. Save pointer to found tree item in given
// location. If no matching item is found, check the "create" flag: If set,
// create new tree item, link to tree, fill with data and store its pointer.
// If "create" is FALSE, store NULL. Returns whether item was created.
extern int Tree_hard_scan(struct rwnode **result, struct rwnode **forest, int id_number, boolean create);
// Call given function for each node of each tree of given forest.
extern void Tree_dump_forest(struct rwnode **, int id_number, void (*)(struct rwnode *, FILE *), FILE *);


#endif
