import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

export type DevicePlatform = 'ios' | 'android';

@Entity('devices')
export class Device {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ name: 'fcm_token', type: 'varchar', length: 255 })
  fcmToken!: string;

  @Column({
    type: 'enum',
    enumName: 'device_platform',
    enum: ['ios', 'android'],
  })
  platform!: DevicePlatform;

  @Column({ name: 'last_active_at', type: 'timestamptz' })
  lastActiveAt!: Date;

  @Column({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
