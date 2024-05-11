package util

import (
	"os"
	"path/filepath"
	"time"
)

func IsSymLink(file os.FileInfo) bool {
	return file.Mode()&os.ModeSymlink != 0
}

func IsSymLinkMode(mode os.FileMode) bool {
	return mode&os.ModeSymlink != 0
}

func IsExecutable(file os.FileInfo) bool {
	return file.Mode()&0o111 != 0
}

func IsExecutableMode(mode os.FileMode) bool {
	return mode&0o111 != 0
}

// RecursivelySizeOf returns the size of the file or directory
// depth < 0 means no limit
func RecursivelySizeOf(info os.FileInfo, depth int) int64 {
	currentDepth := 0
	if info.IsDir() {
		totalSize := info.Size()
		if depth < 0 {
			// -1 means no limit
			_ = filepath.WalkDir(
				info.Name(), func(path string, dir os.DirEntry, err error) error {
					if err != nil {
						return err
					}

					if !dir.IsDir() {
						info, err := dir.Info()
						if err == nil {
							totalSize += info.Size()
						}
					}

					return nil
				},
			)
		} else {
			_ = filepath.WalkDir(
				info.Name(), func(path string, dir os.DirEntry, err error) error {
					if err != nil {
						return err
					}
					if currentDepth > depth {
						if dir.IsDir() {
							return filepath.SkipDir
						}
						return nil
					}

					if !dir.IsDir() {
						info, err := dir.Info()
						if err == nil {
							totalSize += info.Size()
						}
					}

					if dir.IsDir() {
						currentDepth++
					}

					return nil
				},
			)
		}

		return totalSize
	}
	return info.Size()
}

type MockFileInfo struct {
	size    int64
	isDir   bool
	name    string
	mode    os.FileMode
	modTime time.Time
}

func NewMockFileInfo(size int64, isDir bool, name string, mode os.FileMode, modTime time.Time) *MockFileInfo {
	return &MockFileInfo{size: size, isDir: isDir, name: name, mode: mode, modTime: modTime}
}

func (m *MockFileInfo) Size() int64 {
	return m.size
}

func (m *MockFileInfo) IsDir() bool {
	return m.isDir
}

func (m *MockFileInfo) Mode() os.FileMode {
	return m.mode
}

func (m *MockFileInfo) ModTime() time.Time {
	return m.modTime
}

func (m *MockFileInfo) Name() string {
	return m.name
}

func (m *MockFileInfo) Sys() any {
	return nil
}
