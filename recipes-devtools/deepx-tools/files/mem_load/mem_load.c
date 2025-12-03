// SPDX-License-Identifier: GPL-2.0
/*
 * memwrite - Write file contents to physical memory address
 *
 * This utility writes a file to a specified physical memory address using
 * mmap(). It handles 4-byte alignment requirements and works with /dev/mem
 * or similar memory device files.
 */

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>

#define ALIGN_SIZE	4
#define DEFAULT_MEM_DEV	"/dev/mem"

static void print_usage(const char *prog_name)
{
	fprintf(stderr, "Usage: %s -f <file> -a <addr> [-m <mem_device>]\n", prog_name);
	fprintf(stderr, " -f <file>        : Input file path\n");
	fprintf(stderr, " -a <addr>        : Physical memory address (hex)\n");
	fprintf(stderr, " -m <mem_device>  : Memory device (default: %s)\n", DEFAULT_MEM_DEV);
}

static int validate_alignment(unsigned long addr)
{
	if (addr % ALIGN_SIZE != 0) {
		fprintf(stderr, "Error: Address 0x%lx is not %d-byte aligned\n",
			addr, ALIGN_SIZE);
		fprintf(stderr, "Hardware requires aligned memory access\n");
		return -1;
	}
	return 0;
}

static ssize_t get_file_size(int fd, const char *filename)
{
	struct stat st;

	if (fstat(fd, &st) < 0) {
		fprintf(stderr, "Error: Failed to stat file '%s': %s\n", filename, strerror(errno));
		return -1;
	}

	if (st.st_size == 0) {
		fprintf(stderr, "Error: File is empty\n");
		return -1;
	}

	return st.st_size;
}

static unsigned char *read_file_aligned(int fd, size_t size, size_t *aligned_size)
{
	unsigned char *buf;
	ssize_t bytes_read;
	size_t padding = 0;

	*aligned_size = size;
	if (size % ALIGN_SIZE != 0) {
		padding = ALIGN_SIZE - (size % ALIGN_SIZE);
		*aligned_size = size + padding;
		printf("Warning: File size %zu not %d-byte aligned, "
		       "padding %zu bytes\n", size, ALIGN_SIZE, padding);
	}

	buf = calloc(1, *aligned_size);
	if (!buf) {
		fprintf(stderr, "Error: Failed to allocate %zu bytes\n", *aligned_size);
		return NULL;
	}

	bytes_read = read(fd, buf, size);
	if (bytes_read != (ssize_t)size) {
		fprintf(stderr, "Error: Failed to read file: %s\n",
			strerror(errno));
		free(buf);
		return NULL;
	}

	return buf;
}

static int write_to_physical_memory(const char *mem_device,
				    unsigned long phys_addr, unsigned char *data, size_t size)
{
	int mem_fd;
	void *mapped;
	unsigned long page_size, page_base, page_offset;
	size_t map_size;
	volatile unsigned char *dest;
	size_t i;
	int ret = 0;

	mem_fd = open(mem_device, O_RDWR | O_SYNC);
	if (mem_fd < 0) {
		fprintf(stderr, "Error: Failed to open '%s': %s\n", mem_device, strerror(errno));
		fprintf(stderr, "Hint: Try running with sudo or as root\n");
		return -1;
	}

	page_size = sysconf(_SC_PAGESIZE);
	page_base = phys_addr & ~(page_size - 1);
	page_offset = phys_addr - page_base;
	map_size = page_offset + size;

	mapped = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, mem_fd, page_base);
	if (mapped == MAP_FAILED) {
		fprintf(stderr, "Error: mmap failed at 0x%lx (size %zu): %s\n",
				page_base, map_size, strerror(errno));
		ret = -1;
		goto close_fd;
	}

	/*
	 * Use byte-by-byte copy to avoid bus errors on unaligned or
	 * hardware-restricted memory regions that don't support word access
	 */
	dest = (volatile unsigned char *)mapped + page_offset;
	for (i = 0; i < size; i++)
		dest[i] = data[i];

	/* Ensure all writes are flushed to hardware */
	if (msync(mapped, map_size, MS_SYNC) < 0) {
		fprintf(stderr, "Warning: msync failed: %s\n", strerror(errno));
	}

	munmap(mapped, map_size);

close_fd:
	close(mem_fd);
	return ret;
}

int main(int argc, char **argv)
{
	char *input_file = NULL;
	char *mem_device = DEFAULT_MEM_DEV;
	unsigned long phys_addr = 0;
	int opt, fd, ret = 1;
	ssize_t file_size;
	size_t aligned_size;
	unsigned char *data = NULL;

	while ((opt = getopt(argc, argv, "f:a:m:h")) != -1) {
		switch (opt) {
		case 'f':
			input_file = optarg;
			break;
		case 'a':
			phys_addr = strtoul(optarg, NULL, 0);
			break;
		case 'm':
			mem_device = optarg;
			break;
		case 'h':
			print_usage(argv[0]);
			return 0;
		default:
			print_usage(argv[0]);
			return 1;
		}
	}

	if (!input_file || phys_addr == 0) {
		fprintf(stderr, "Error: Missing required arguments\n\n");
		print_usage(argv[0]);
		return 1;
	}

	if (validate_alignment(phys_addr) < 0)
		return 1;

	fd = open(input_file, O_RDONLY);
	if (fd < 0) {
		fprintf(stderr, "Error: Failed to open file '%s': %s\n", input_file, strerror(errno));
		return 1;
	}

	file_size = get_file_size(fd, input_file);
	if (file_size < 0)
		goto close_file;

	printf("Input file: %s (%zd bytes)\n", input_file, file_size);
	printf("Target address: 0x%lx\n", phys_addr);
	printf("Memory device: %s\n", mem_device);

	data = read_file_aligned(fd, file_size, &aligned_size);
	if (!data)
		goto close_file;

	if (aligned_size != (size_t)file_size)
		printf("Aligned size: %zu bytes\n", aligned_size);

	if (write_to_physical_memory(mem_device, phys_addr, data, aligned_size) < 0)
		goto free_data;

	printf("Successfully wrote %zd bytes to physical address 0x%lx\n",
	       file_size, phys_addr);
	ret = 0;

free_data:
	free(data);

close_file:
	close(fd);

	return ret;
}

