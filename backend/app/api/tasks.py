from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user, RequireRole
from app.core.cache import cache_get, cache_set, cache_delete_pattern
from app.models.task import Task
from app.models.user import User
from app.schemas.schemas import TaskCreate, TaskUpdate, TaskOut

router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.get("", response_model=list[TaskOut])
def list_tasks(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    cache_key = f"tasks:user:{user.id}"
    cached = cache_get(cache_key)
    if cached:
        return cached

    query = db.query(Task)
    if user.role != "admin":
        query = query.filter(Task.owner_id == user.id)
    tasks = query.order_by(Task.created_at.desc()).all()

    result = [TaskOut.model_validate(t).model_dump(mode="json") for t in tasks]
    cache_set(cache_key, result, ttl=30)
    return tasks


@router.post("", response_model=TaskOut, status_code=201)
def create_task(payload: TaskCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    task = Task(**payload.model_dump(), owner_id=user.id)
    db.add(task)
    db.commit()
    db.refresh(task)
    cache_delete_pattern(f"tasks:user:{user.id}*")
    return task


@router.patch("/{task_id}", response_model=TaskOut)
def update_task(task_id: int, payload: TaskUpdate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(404, "Task not found")
    if task.owner_id != user.id and user.role not in ("admin", "manager"):
        raise HTTPException(403, "Not allowed to modify this task")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(task, field, value)
    db.commit()
    db.refresh(task)
    cache_delete_pattern(f"tasks:user:{task.owner_id}*")
    return task


@router.delete("/{task_id}", status_code=204, dependencies=[Depends(RequireRole(["admin", "manager"]))])
def delete_task(task_id: int, db: Session = Depends(get_db)):
    """Only admin/manager can delete - RBAC example."""
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(404, "Task not found")
    owner_id = task.owner_id
    db.delete(task)
    db.commit()
    cache_delete_pattern(f"tasks:user:{owner_id}*")
