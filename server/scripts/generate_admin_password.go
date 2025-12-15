package main

import (
	"fmt"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	password := "wq123123"
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		fmt.Printf("生成密码哈希失败: %v\n", err)
		return
	}
	fmt.Printf("密码: %s\n", password)
	fmt.Printf("Bcrypt 哈希: %s\n", string(hash))
}
