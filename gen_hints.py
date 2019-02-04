#!/usr/bin/env python3
import sys
import heapq

# Generates gawk code. Run this manually and update hinter.awk if you don't like current alphabet or want to increase number of hints.
#
# This script builds prefix code for given number of hints using n-aray Huffman Coding.
# We precompute hints for hinter.awk to make it fast (and to avoid implementing priority queue in awk).

alphabet = list('sadfjklewcmvpghru')
alphabet_size = len(alphabet)

def generate_hints(num_hints_needed):
    def huffman_build_tree(num_hints_needed):
        heap = [(1, [i], []) for i in range(num_hints_needed)]
        heapq.heapify(heap)

        if num_hints_needed <= alphabet_size:
            first_step_num_children = num_hints_needed
        else:
            first_step_num_children = [m for m in range(2, num_hints_needed) 
                    if m % (alphabet_size - 1) == num_hints_needed % (alphabet_size - 1)][0] 

        while len(heap) > 1:
            children = []
            while len(heap) > 0 and len(children) < first_step_num_children:
                children.append(heapq.heappop(heap))

            new_node = (sum(node[0] for node in children), 
                    sum([node[1] for node in children], []), 
                    [node for node in children])
            heapq.heappush(heap, new_node)
            first_step_num_children = alphabet_size
        return heap[0]

    def generate_codes(tree, code):
        if len(tree[1]) == 1:
            yield code

        assert len(tree[2]) <= alphabet_size
        for child, char in zip(tree[2], alphabet):
            yield from generate_codes(child, code + char)

    tree = huffman_build_tree(num_hints_needed)
    yield from generate_codes(tree, code='')

def generate_gawk_hints():
    statement = '\nif'
    sizes = [alphabet_size, 30, 50, 80, 110, 150, 200, 300, 500, 1000]
    for num_hints_needed in sizes:
        hints_string = ' '.join(generate_hints(num_hints_needed))
        if num_hints_needed == sizes[-1]:
            print(' else {')
        else:
            print('%s (num_hints_needed <= %d) {' % (statement, num_hints_needed))
        print('    split("%s", HINTS]);' % (hints_string))
        print('}', end='')
        statement = ' else if'
    print("")

generate_gawk_hints()
