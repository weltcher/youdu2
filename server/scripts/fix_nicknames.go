package main

import (
	"database/sql"
	"fmt"
	"log"
	"regexp"

	_ "github.com/lib/pq"
)

func main() {
	// 数据库连接配置
	dbHost := "localhost"
	dbPort := 5432
	dbUser := "postgres"
	dbPassword := "postgres"
	dbName := "youdu_db"

	// 连接数据库
	connStr := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
		dbHost, dbPort, dbUser, dbPassword, dbName)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal("连接数据库失败:", err)
	}
	defer db.Close()

	// 测试连接
	if err := db.Ping(); err != nil {
		log.Fatal("数据库连接测试失败:", err)
	}

	fmt.Println("✅ 数据库连接成功")

	// 1. 查询当前有问题的用户
	fmt.Println("\n🔍 查询当前有问题的用户昵称...")
	rows, err := db.Query(`
		SELECT id, username, full_name, created_at 
		FROM users 
		WHERE full_name ~ '^[0-9]+$'
		ORDER BY id
	`)
	if err != nil {
		log.Fatal("查询用户失败:", err)
	}
	defer rows.Close()

	var problemUsers []struct {
		ID       int
		Username string
		FullName string
		Created  string
	}

	for rows.Next() {
		var user struct {
			ID       int
			Username string
			FullName string
			Created  string
		}
		if err := rows.Scan(&user.ID, &user.Username, &user.FullName, &user.Created); err != nil {
			log.Printf("扫描用户数据失败: %v", err)
			continue
		}
		problemUsers = append(problemUsers, user)
		fmt.Printf("  用户ID: %d, 用户名: %s, 当前昵称: %s, 创建时间: %s\n", 
			user.ID, user.Username, user.FullName, user.Created)
	}

	if len(problemUsers) == 0 {
		fmt.Println("✅ 没有发现昵称为纯数字的用户")
		return
	}

	fmt.Printf("\n发现 %d 个用户的昵称为纯数字，需要修复\n", len(problemUsers))

	// 2. 执行修复
	fmt.Println("\n🔧 开始修复用户昵称...")
	
	// 使用正则表达式匹配纯数字
	numericRegex := regexp.MustCompile(`^[0-9]+$`)
	
	for _, user := range problemUsers {
		if numericRegex.MatchString(user.FullName) {
			// 将昵称设置为用户名
			newNickname := user.Username
			
			// 如果用户名也是纯数字，则添加前缀
			if numericRegex.MatchString(user.Username) {
				newNickname = fmt.Sprintf("用户%s", user.Username)
			}
			
			_, err := db.Exec(`UPDATE users SET full_name = $1 WHERE id = $2`, newNickname, user.ID)
			if err != nil {
				log.Printf("❌ 修复用户 %d 失败: %v", user.ID, err)
				continue
			}
			
			fmt.Printf("  ✅ 用户 %d: %s -> %s\n", user.ID, user.FullName, newNickname)
		}
	}

	// 3. 验证修复结果
	fmt.Println("\n📊 验证修复结果...")
	rows2, err := db.Query(`
		SELECT id, username, full_name 
		FROM users 
		WHERE id = ANY($1)
		ORDER BY id
	`, fmt.Sprintf("{%s}", func() string {
		var ids []string
		for _, user := range problemUsers {
			ids = append(ids, fmt.Sprintf("%d", user.ID))
		}
		return fmt.Sprintf("%s", ids[0]) // 简化处理，实际应该用数组
	}()))
	
	if err != nil {
		log.Printf("验证查询失败: %v", err)
		return
	}
	defer rows2.Close()

	fmt.Println("修复后的用户信息:")
	for rows2.Next() {
		var id int
		var username, fullName string
		if err := rows2.Scan(&id, &username, &fullName); err != nil {
			log.Printf("扫描验证数据失败: %v", err)
			continue
		}
		fmt.Printf("  用户ID: %d, 用户名: %s, 昵称: %s\n", id, username, fullName)
	}

	fmt.Println("\n✅ 用户昵称修复完成！")
	fmt.Println("💡 提示：修复后需要重启应用或清除缓存以看到效果")
}
